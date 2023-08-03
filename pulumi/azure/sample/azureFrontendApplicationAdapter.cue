package azureFrontendApplicationAdapter

import (
	"qmonus.net/adapter/official/pulumi/azure/sample:azureFrontendApplicationAdapterForAzureResources"
	"qmonus.net/adapter/official/pipeline/deploy:azureStaticWebApps"
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
				azureStaticSiteName:     parameters.azureStaticSiteName
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
	]
	resources: app: {}
	pipelines: {}
}
