package azureAppServicePlan

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
		appServicePlan: azure.#AzureAppServicePlan & {
			options: _azureProvider
			properties: {
				name:                      "qvs-\(parameters.appName)-asp"
				resourceGroupName:         parameters.azureResourceGroupName
				kind:                      "linux"
				location:                  "japaneast"
				maximumElasticWorkerCount: 1
				reserved:                  true
				sku: {
					capacity: 1
					family:   "Pv3"
					name:     "P1v3"
					size:     "P1v3"
					tier:     "PremiumV3"
				}
			}
		}
	}
}
