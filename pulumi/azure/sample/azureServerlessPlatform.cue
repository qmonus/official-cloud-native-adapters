package azureServerlessPlatform

import (
	"qmonus.net/adapter/official/pulumi/provider:azure"
	"qmonus.net/adapter/official/pulumi/provider:azureclassic"
	"qmonus.net/adapter/official/pulumi/provider:random"
	"qmonus.net/adapter/official/pulumi/azure/sample/component:azureCacheForRedis"
	"qmonus.net/adapter/official/pulumi/azure/sample/component:azureContainerRegistry"
	"qmonus.net/adapter/official/pulumi/azure/sample/component:azureDatabaseForMysql"
	"qmonus.net/adapter/official/pulumi/azure/sample/component:azureDnsZone"
	"qmonus.net/adapter/official/pulumi/azure/sample/component:azureKeyVault"
	"qmonus.net/adapter/official/pulumi/azure/sample/component:azureResourceGroup"
	"qmonus.net/adapter/official/pulumi/azure/sample/component:azureVirtualNetwork"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	name: "sample:azureServerlessPlatform"

	parameters: {
		appName:                string
		azureTenantId:          string
		azureSubscriptionId:    string
		azureResourceGroupName: string
		mysqlSkuName:           string | *"B_Standard_B2s"
		mysqlVersion:           string | *"8.0.21"
		dnsZoneName:            string
		keyVaultAccessAllowedObjectIds: [...string]
	}

	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
		{
			pattern: azure.DesignPattern
			params: {
				providerName: "AzureProvider"
			}
		},
		{
			pattern: azureclassic.DesignPattern
			params: {
				providerName: "AzureClassicProvider"
			}
		},
		{
			pattern: random.DesignPattern
			params: {
				providerName: "RandomProvider"
			}
		},
		{
			pattern: azureCacheForRedis.DesignPattern
			params: {
				appName: parameters.appName
			}
		},
		{
			pattern: azureContainerRegistry.DesignPattern
			params: {
				appName: parameters.appName
			}
		},
		{
			pattern: azureDatabaseForMysql.DesignPattern
			params: {
				appName:      parameters.appName
				mysqlSkuName: parameters.mysqlSkuName
				mysqlVersion: parameters.mysqlVersion
			}
		},
		{
			pattern: azureDnsZone.DesignPattern
			params: {
				appName:     parameters.appName
				dnsZoneName: parameters.dnsZoneName
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
		{
			pattern: simpleDeployByPulumiYaml.DesignPattern
			pipelineParams: {
				repositoryKind:   pipelineParameters.repositoryKind
				useDebug:         false
				deployPhase:      "app"
				resourcePriority: "medium"
				useSshKey:        pipelineParameters.useSshKey
				//    pulumiCredentialName: "qmonus-pulumi-secret"
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
	pipelines: _
}
