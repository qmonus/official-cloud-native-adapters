package azureContainerRegistry

import (
	"qmonus.net/adapter/official/pulumi:utils"
	"qmonus.net/adapter/official/pulumi/base/azure"
	"qmonus.net/adapter/official/pulumi/base/random"
)

DesignPattern: {
	name: "sample:azureContainerRegistry"

	parameters: {
		appName: string
	}

	_azureProvider: provider:  "${AzureProvider}"
	_randomProvider: provider: "${RandomProvider}"

	resources: app: {
		registryNameSuffix: random.#Resource & {
			options: _randomProvider
			type:    "random:RandomString"
			properties: {
				length:  8
				special: false
			}
		}

		containerRegistry: azure.#Resource & {
			type:    "azure-native:containerregistry:Registry"
			options: _azureProvider
			properties: {
				adminUserEnabled:  true
				location:          "japaneast"
				resourceGroupName: "${resourceGroup.name}"
				registryName:      {
					utils.#kebabToPascal
					input: "qvs-\(parameters.appName)-registry-${registryNameSuffix.result}"
				}.out
				sku: name:          "Premium"
				tags: "managed-by": "Qmonus Value Stream"
			}
		}
	}
}
