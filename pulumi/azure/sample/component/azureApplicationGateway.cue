package azureApplicationGateway

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureApplicationGateway"

	parameters: {
		appName:             string
		azureSubscriptionId: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		applicationGateway: azure.#Resource & {
			type:    "azure-native:network:ApplicationGateway"
			options: _azureProvider
			properties: {
				resourceGroupName:      "${resourceGroup.name}"
				applicationGatewayName: "qvs-\(parameters.appName)-application-gateway"
				backendAddressPools: [{
					name: "default-backend-address-pool"
				}]
				backendHttpSettingsCollection: [{
					name:           "default-http-setting"
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
					backendAddressPool: id:  "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/backendAddressPools/default-backend-address-pool"
					backendHttpSettings: id: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/backendHttpSettingsCollection/default-http-setting"
					httpListener: id:        "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}/providers/Microsoft.Network/applicationGateways/qvs-\(parameters.appName)-application-gateway/httpListeners/default-http-listener"
					name:     "default-request-routing-rules"
					priority: 20000
				}]
				sku: {
					capacity: 2
					name:     "Standard_v2"
					tier:     "Standard_v2"
				}
				tags: "managed-by": "Qmonus Value Stream"
				zones: ["1"]
			}
		}
	}
}
