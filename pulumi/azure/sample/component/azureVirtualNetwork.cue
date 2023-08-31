package azureVirtualNetwork

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureVirtualNetwork"

	parameters: {
		appName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		virtualNetwork: azure.#Resource & {
			type: "azure-native:network:VirtualNetwork"
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
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		virtualNetworkAksSubnet: azure.#Resource & {
			type:    "azure-native:network:Subnet"
			options: _azureProvider
			properties: {
				resourceGroupName:  "${resourceGroup.name}"
				subnetName:         "${virtualNetwork.name}-aks-subnet"
				addressPrefix:      "10.0.0.0/22"
				virtualNetworkName: "${virtualNetwork.name}"
				networkSecurityGroup: id: "${networkSecurityGroupAKS.id}"
			}
		}

		virtualNetworkApplicationGatewaySubnet: azure.#Resource & {
			type: "azure-native:network:Subnet"
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

		networkSecurityGroupAKS: azure.#Resource & {
			type:    "azure-native:network:NetworkSecurityGroup"
			options: _azureProvider
			properties: {
				resourceGroupName:        "${resourceGroup.name}"
				networkSecurityGroupName: "qvs-\(parameters.appName)-aks-nsg"
				location:                 "japaneast"
				tags: "managed-by": "Qmonus Value Stream"
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

		networkSecurityGroupApplicationGateway: azure.#Resource & {
			type:    "azure-native:network:NetworkSecurityGroup"
			options: _azureProvider
			properties: {
				resourceGroupName:        "${resourceGroup.name}"
				networkSecurityGroupName: "qvs-\(parameters.appName)-application-gateway-nsg"
				location:                 "japaneast"
				tags: "managed-by": "Qmonus Value Stream"
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
}
