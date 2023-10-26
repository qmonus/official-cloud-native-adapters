package azureContainerRegistry

import (
	"qmonus.net/adapter/official/adapters:utils"
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:random"
)

DesignPattern: {
	parameters: {
		appName: string
	}

	_azureProvider: provider:  "${AzureProvider}"
	_randomProvider: provider: "${RandomProvider}"

	resources: app: {
		registryNameSuffix: random.#RandomString & {
			options: _randomProvider
			properties: {
				length:  8
				special: false
			}
		}

		containerRegistry: azure.#AzureContainerRegistry & {
			options: _azureProvider
			properties: {
				adminUserEnabled:  true
				location:          "japaneast"
				resourceGroupName: "${resourceGroup.name}"
				registryName:      {
					utils.#kebabToPascal
					input: "qvs-\(parameters.appName)-registry-${registryNameSuffix.result}"
				}.out
				sku: name: "Premium"
			}
		}
	}
}
