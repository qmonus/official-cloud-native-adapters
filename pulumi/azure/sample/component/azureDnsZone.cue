package azureDnsZone

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureDnsZone"

	parameters: {
		appName:     string
		dnsZoneName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		dnsZone: azure.#Resource & {
			type:    "azure-native:network:Zone"
			options: _azureProvider
			properties: {
				zoneName:          parameters.dnsZoneName
				resourceGroupName: "${resourceGroup.name}"
				location:          "Global"
				tags: "managed-by": "Qmonus Value Stream"
				zoneType: "Public"
			}
		}
	}
}
