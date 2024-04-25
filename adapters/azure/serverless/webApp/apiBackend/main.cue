package apiBackend

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:base"
	"qmonus.net/adapter/official/adapters/azure/component:azureAppServicePlan"
	"qmonus.net/adapter/official/adapters/azure/component:azureWebAppForContainers"
	"qmonus.net/adapter/official/adapters/azure/component:azureDiagnosticSetting"
	"qmonus.net/adapter/official/pipeline/build:buildkitAzure"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
	"qmonus.net/adapter/official/pipeline/sample:getUrlOfAzureAppService"

	"strconv"
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
		args?: [...string]
		environmentVariables: [string]: string
		secrets: [string]:              base.#Secret
		appServiceAllowedSourceIps: [...string] | *[]
		logAnalyticsWorkspaceId?:   string
		enableContainerLog:         string | *"true"
	}

	let _enableContainerLog = strconv.ParseBool(parameters.enableContainerLog)

	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
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
				environmentVariables:          parameters.environmentVariables
				secrets:                       parameters.secrets
				appServiceAllowedSourceIps:    parameters.appServiceAllowedSourceIps
				if parameters.subnetId != "" {
					subnetId: parameters.subnetId
				}
				if parameters.args != _|_ {
					args: parameters.args
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
		if _enableContainerLog {
			{
				pattern: azureDiagnosticSetting.DesignPattern
				params: {
					appName:                parameters.appName
					azureResourceGroupName: parameters.azureResourceGroupName
					if parameters.logAnalyticsWorkspaceId != _|_ {
						logAnalyticsWorkspaceId: parameters.logAnalyticsWorkspaceId
					}
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
		{
			pattern: getUrlOfAzureAppService.DesignPattern
		},
	]

	let _azureProvider = "AzureProvider"
	let _azureClassicProvider = "AzureClassicProvider"

	parameters: #resourceId: {
		azureProvider:        _azureProvider
		azureClassicProvider: _azureClassicProvider
	}

	resources: app: {
		"\(_azureProvider)": azure.#AzureProvider

		"\(_azureClassicProvider)": azure.#AzureClassicProvider
	}

	pipelines: _
}
