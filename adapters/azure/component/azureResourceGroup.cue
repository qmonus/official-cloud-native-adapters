package azureResourceGroup

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureResourceGroup"

	parameters: {
		appName:                string
		azureResourceGroupName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		resourceGroup: azure.#Resource & {
			type:    "azure-native:resources:ResourceGroup"
			options: _azureProvider
			properties: {
				location:          "japaneast"
				resourceGroupName: parameters.azureResourceGroupName
				tags: "managed-by": "Qmonus Value Stream"
			}
		}
	}
}
