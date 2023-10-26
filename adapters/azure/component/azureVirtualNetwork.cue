package azureVirtualNetwork

import (
	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName:               string
		useAKS:                bool | *true
		useApplicationGateway: bool | *true
		useAppService:         bool | *false
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		virtualNetwork: azure.#AzureVirtualNetwork & {
			options: {
				// Ignore VNET rewriting due to subnet resource creation
				ignoreChanges: ["subnets"]
				_azureProvider
			}
			properties: {
				resourceGroupName:  "${resourceGroup.name}"
				location:           "japaneast"
				virtualNetworkName: "qvs-\(parameters.appName)-vnet"
				addressSpace: addressPrefixes: ["10.0.0.0/16"]
			}
		}

		if parameters.useAKS {
			virtualNetworkAksSubnet: azure.#AzureSubnet & {
				options: _azureProvider
				properties: {
					resourceGroupName:  "${resourceGroup.name}"
					subnetName:         "${virtualNetwork.name}-aks-subnet"
					addressPrefix:      "10.0.0.0/22"
					virtualNetworkName: "${virtualNetwork.name}"
					networkSecurityGroup: id: "${networkSecurityGroupAKS.id}"
				}
			}

			networkSecurityGroupAKS: azure.#AzureNetworkSecurityGroup & {
				options: _azureProvider
				properties: {
					resourceGroupName:        "${resourceGroup.name}"
					networkSecurityGroupName: "qvs-\(parameters.appName)-aks-nsg"
					location:                 "japaneast"
					securityRules: [{
						access:                   "Allow"
						destinationAddressPrefix: '*'
						destinationPortRange:     '*'
						direction:                "Inbound"
						name:                     "public-inbound-rule"
						priority:                 2000
						protocol:                 '*'
						sourceAddressPrefix:      '*'
						sourcePortRange:          '*'
					}]
				}
			}
		}

		if parameters.useApplicationGateway {
			virtualNetworkApplicationGatewaySubnet: azure.#AzureSubnet & {
				options: {
					dependsOn: ["${virtualNetworkAksSubnet}"]
					_azureProvider
				}
				properties: {
					resourceGroupName:  "${resourceGroup.name}"
					subnetName:         "${virtualNetwork.name}-application-gateway-subnet"
					addressPrefix:      "10.0.4.0/22"
					virtualNetworkName: "${virtualNetwork.name}"
					networkSecurityGroup: id: "${networkSecurityGroupApplicationGateway.id}"
				}
			}

			networkSecurityGroupApplicationGateway: azure.#AzureNetworkSecurityGroup & {
				options: _azureProvider
				properties: {
					resourceGroupName:        "${resourceGroup.name}"
					networkSecurityGroupName: "qvs-\(parameters.appName)-application-gateway-nsg"
					location:                 "japaneast"
					securityRules: [{
						// Specific security rules required for application gateways
						access:                   "Allow"
						destinationAddressPrefix: '*'
						destinationPortRange:     '65200-65535'
						direction:                "Inbound"
						name:                     "application-gateway-specific-rule"
						priority:                 1000
						protocol:                 '*'
						sourceAddressPrefix:      '*'
						sourcePortRange:          '*'
					}, {
						access:                   "Allow"
						destinationAddressPrefix: '*'
						destinationPortRange:     '*'
						direction:                "Inbound"
						name:                     "public-inbound-rule"
						priority:                 2000
						protocol:                 '*'
						sourceAddressPrefix:      '*'
						sourcePortRange:          '*'
					}]
				}
			}
		}

		if parameters.useAppService {
			virtualNetworkWebAppSubnet: azure.#AzureSubnet & {
				options: _azureProvider
				properties: {
					resourceGroupName:  "${resourceGroup.name}"
					subnetName:         "${virtualNetwork.name}-web-app-subnet"
					addressPrefix:      "10.0.8.0/22"
					virtualNetworkName: "${virtualNetwork.name}"
					networkSecurityGroup: id: "${networkSecurityGroupWebApp.id}"
					delegations: [{
						name:        "serverfarms"
						serviceName: "Microsoft.Web/serverfarms"
					}]
				}
			}

			networkSecurityGroupWebApp: azure.#AzureNetworkSecurityGroup & {
				options: _azureProvider
				properties: {
					resourceGroupName:        "${resourceGroup.name}"
					networkSecurityGroupName: "qvs-\(parameters.appName)-web-app-nsg"
					location:                 "japaneast"
					securityRules: [{
						access:                   "Allow"
						destinationAddressPrefix: '*'
						destinationPortRange:     '*'
						direction:                "Inbound"
						name:                     "public-inbound-rule"
						priority:                 2000
						protocol:                 '*'
						sourceAddressPrefix:      '*'
						sourcePortRange:          '*'
					}]
				}
			}
		}
	}
}
