package azureResourceGroup

import (
	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName:                string
		azureResourceGroupName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		resourceGroup: azure.#AzureResourceGroup & {
			options: _azureProvider
			properties: {
				location:          "japaneast"
				resourceGroupName: parameters.azureResourceGroupName
			}
		}
	}
}
