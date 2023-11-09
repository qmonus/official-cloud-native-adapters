package sharedInfrastructure

import (
	"strconv"

	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/adapters/azure/component:azureCacheForRedis"
	"qmonus.net/adapter/official/adapters/azure/component:azureContainerRegistry"
	"qmonus.net/adapter/official/adapters/azure/component:azureDatabaseForMysql"
	"qmonus.net/adapter/official/adapters/azure/component:azureKeyVault"
	"qmonus.net/adapter/official/adapters/azure/component:azureResourceGroup"
	"qmonus.net/adapter/official/adapters/azure/component:azureVirtualNetwork"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                string
		azureTenantId:          string
		azureSubscriptionId:    string
		azureResourceGroupName: string
		mysqlSkuName:           string | *"B_Standard_B2s"
		mysqlVersion:           string | *"8.0.21"
		keyVaultAccessAllowedObjectIds: [...string]
		useMySQL: string | *"true"
		useRedis: string | *"true"
	}

	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	let _useMySQL = strconv.ParseBool(parameters.useMySQL)
	let _useRedis = strconv.ParseBool(parameters.useRedis)

	composites: [
		{
			pattern: azureContainerRegistry.DesignPattern
			params: {
				appName: parameters.appName
			}
		},
		{
			pattern: azureKeyVault.DesignPattern
			params: {
				keyVaultAccessAllowedObjectIds: parameters.keyVaultAccessAllowedObjectIds
			}
		},
		{
			pattern: azureResourceGroup.DesignPattern
			params: {
				appName:                parameters.appName
				azureResourceGroupName: parameters.azureResourceGroupName
			}
		},
		{
			pattern: azureVirtualNetwork.DesignPattern
			params: {
				appName:               parameters.appName
				useAKS:                false
				useApplicationGateway: false
				useAppService:         true
			}
		},
		if _useMySQL {
			{
				pattern: azureDatabaseForMysql.DesignPattern
				params: {
					appName:      parameters.appName
					mysqlSkuName: parameters.mysqlSkuName
					mysqlVersion: parameters.mysqlVersion
				}
			}
		},
		if _useRedis {
			{
				pattern: azureCacheForRedis.DesignPattern
				params: {
					appName: parameters.appName
				}
			}
		},
		{
			pattern: simpleDeployByPulumiYaml.DesignPattern
			pipelineParams: {
				repositoryKind:   pipelineParameters.repositoryKind
				useDebug:         false
				deployPhase:      "app"
				resourcePriority: "medium"
				useSshKey:        pipelineParameters.useSshKey
				useCred: {
					kubernetes: false
					gcp:        false
					aws:        false
					azure:      true
				}
				importStackName:   ""
				useBastionSshCred: false
			}
		},
	]

	let _azureProvider = "AzureProvider"
	let _azureClassicProvider = "AzureClassicProvider"
	let _randomProvider = "RandomProvider"

	parameters: #resourceId: {
		azureProvider:        _azureProvider
		azureClassicProvider: _azureClassicProvider
		randomProvider:       _randomProvider
	}

	resources: app: {
		"\(_azureProvider)": azure.#AzureProvider

		"\(_azureClassicProvider)": azure.#AzureClassicProvider

		"\(_randomProvider)": random.#RandomProvider
	}

	pipelines: _
}
