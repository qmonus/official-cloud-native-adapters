package azurePrivateEndpoint

import (
	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		privateEndpoint: azure.#PrivateEndpoint & {
			options: _azureProvider
			properties: {
				privateEndpointName: "qvs-\(parameters.appName)-private-endpoint"
				subnet: id: "${virtualNetworkPrivateEndpointSubnet.id}"
				privateLinkServiceConnections: [{
					name: "qvs-\(parameters.appName)-private-link-service-connection"
					groupIds: ["registry"]
					privateLinkServiceId: "${containerRegistry.id}"
				}]
				resourceGroupName: "${resourceGroup.name}"
				location:          "japaneast"
			}
		}
	}
}
