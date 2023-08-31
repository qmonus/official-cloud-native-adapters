package azurePrivateEndpoint

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azurePrivateEndpoint"

	parameters: {
		appName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		privateEndpoint: azure.#Resource & {
			type:    "azure-native:network:PrivateEndpoint"
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
				tags: "managed-by": "Qmonus Value Stream"
			}
		}
	}
}
