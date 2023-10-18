package apiBackend

import (
	"qmonus.net/adapter/official/pulumi/provider:azure"
	"qmonus.net/adapter/official/pulumi/provider:azureclassic"
	"qmonus.net/adapter/official/adapters/azure/component:azureAppServicePlan"
	"qmonus.net/adapter/official/adapters/azure/component:azureWebAppForContainers"
	"qmonus.net/adapter/official/pipeline/build:buildkitAzure"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                       string
		azureSubscriptionId:           string
		azureResourceGroupName:        string
		azureDnsZoneResourceGroupName: string
		containerRegistryName:         string
		dnsZoneName:                   string
		subDomainName:                 string | *"api"
		subnetId:                      string | *""
		dbHost:                        string
		redisHost:                     string
		azureKeyVaultName:             string
		imageFullNameTag:              string
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
			pattern: azureAppServicePlan.DesignPattern
			params: {
				appName:                parameters.appName
				azureResourceGroupName: parameters.azureResourceGroupName
			}
		},
		{
			pattern: azureWebAppForContainers.DesignPattern
			params: {
				appName:                       parameters.appName
				azureSubscriptionId:           parameters.azureSubscriptionId
				azureResourceGroupName:        parameters.azureResourceGroupName
				azureDnsZoneResourceGroupName: parameters.azureDnsZoneResourceGroupName
				containerRegistryName:         parameters.containerRegistryName
				dnsZoneName:                   parameters.dnsZoneName
				subDomainName:                 parameters.subDomainName
				dbHost:                        parameters.dbHost
				redisHost:                     parameters.redisHost
				azureKeyVaultName:             parameters.azureKeyVaultName
				imageFullNameTag:              parameters.imageFullNameTag
				if parameters.subnetId != "" {
					subnetId: parameters.subnetId
				}
			}
		},
		{
			pattern: buildkitAzure.DesignPattern
			pipelineParams: {
				image:          ""
				repositoryKind: pipelineParameters.repositoryKind
				useSshKey:      pipelineParameters.useSshKey
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
	pipelines: _
}
