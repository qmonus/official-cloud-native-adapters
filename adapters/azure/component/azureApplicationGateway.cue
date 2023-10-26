package azureApplicationGateway

import (
	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName:             string
		azureSubscriptionId: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		applicationGateway: azure.#AzureApplicationGateway & {
			options: _azureProvider
			options: ignoreChanges: [
				"backendAddressPools",
				"backendHttpSettingsCollection",
				"frontendPorts",
				"httpListeners",
				"probes",
				"requestRoutingRules",
				"sslCertificates",
			]
			properties: {
				resourceGroupName:      "${resourceGroup.name}"
				applicationGatewayName: "qvs-\(parameters.appName)-application-gateway"
				backendAddressPools: [{
					name: "defaultaddresspool"
				}]
				backendHttpSettingsCollection: [{
					name:           "defaulthttpsetting"
					port:           80
					protocol:       "Http"
					requestTimeout: 30
				}]
				frontendIPConfigurations: [{
					name: "application-gateway-public-ip-address"
					publicIPAddress: id: "${applicationGatewayPublicIpAddress.id}"
				}]
				frontendPorts: [{
					name: "default-frontend-port"
					port: 80
				}]
				gatewayIPConfigurations: [{
					name: "application-gateway-subnet"
					subnet: id: "${virtualNetworkApplicationGatewaySubnet.id}"
				}]
				httpListeners: [{
					frontendIPConfiguration: id: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/frontendIPConfigurations/application-gateway-public-ip-address"
					frontendPort: id:            "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/frontendPorts/default-frontend-port"
					name:     "default-http-listener"
					protocol: "Http"
				}]
				location: "japaneast"
				requestRoutingRules: [{
					backendAddressPool: id:  "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/backendAddressPools/defaultaddresspool"
					backendHttpSettings: id: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/backendHttpSettingsCollection/defaulthttpsetting"
					httpListener: id:        "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/httpListeners/default-http-listener"
					name:     "default-request-routing-rules"
					priority: 20000
				}]
				sku: {
					capacity: 2
					name:     "Standard_v2"
					tier:     "Standard_v2"
				}
				zones: ["1"]
			}
		}
	}
}
