package azureDnsZone

import (
	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName:     string
		dnsZoneName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		dnsZone: azure.#AzureDnsZone & {
			options: _azureProvider
			properties: {
				zoneName:          parameters.dnsZoneName
				resourceGroupName: "${resourceGroup.name}"
				location:          "Global"
				zoneType:          "Public"
			}
		}
	}
}
