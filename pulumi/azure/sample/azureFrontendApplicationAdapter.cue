package azureFrontendApplicationAdapter

import (
	"qmonus.net/adapter/official/pulumi/azure/sample:azureFrontendApplicationAdapterForAzureResources"
	"qmonus.net/adapter/official/pulumi/provider:azure"
	"qmonus.net/adapter/official/pipeline/deploy:azureStaticWebApps"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	name: "azure:azureFrontendApplicationAdapter"

	parameters: {
		azureFrontendApplicationAdapterForAzureResources.DesignPattern.parameters
	}
	pipelineParameters: {
		azureStaticWebApps.DesignPattern.pipelineParameters
	}

	group: string

	composites: [
		{
			pattern: azureFrontendApplicationAdapterForAzureResources.DesignPattern
			params: {
				appName:                 parameters.appName
				azureProvider:           parameters.azureProvider
				azureStaticSiteLocation: parameters.azureStaticSiteLocation
				azureSubscriptionId:     parameters.azureSubscriptionId
				azureResourceGroupName:  parameters.azureResourceGroupName
				azureDnsZoneName:        parameters.azureDnsZoneName
			}
			group: group
		}, {
			pattern: azureStaticWebApps.DesignPattern
			pipelineParams: {
				repositoryKind: pipelineParameters.repositoryKind
				useSshKey:      pipelineParameters.useSshKey
			}
		},
		{
			pattern: azure.DesignPattern
			params: {
				providerName: "AzureProvider"
			}
		},
		{
			pattern: simpleDeployByPulumiYaml.DesignPattern
			pipelineParams: {
				repositoryKind:       pipelineParameters.repositoryKind
				useDebug:             false
				deployPhase:          "app"
				resourcePriority:     "medium"
				useSshKey:            pipelineParameters.useSshKey
				pulumiCredentialName: "qmonus-pulumi-secret"
				useCred: {
					kubernetes: false
					gcp:        false
					aws:        false
					azure:      true
				}
				importStackName: ""
			}
		},
	]
	resources: app: {}
	pipelines: {}
}
