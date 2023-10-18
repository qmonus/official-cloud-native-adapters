package frontend

import (
	"qmonus.net/adapter/official/pulumi/provider:azure"
	"qmonus.net/adapter/official/adapters/azure/component:azureStaticWebApps"
	publishSite "qmonus.net/adapter/official/pipeline/deploy:azureStaticWebApps"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                       string
		azureStaticSiteLocation:       string | *"East Asia"
		azureSubscriptionId:           string
		azureResourceGroupName:        string
		azureDnsZoneResourceGroupName: string
		azureDnsZoneName:              string
		relativeRecordSetName:         string | *"www"
		azureCnameRecordTtl:           string | *"3600"
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
		}, {
			pattern: azureStaticWebApps.DesignPattern
			params: {
				appName:                       parameters.appName
				azureStaticSiteLocation:       parameters.azureStaticSiteLocation
				azureSubscriptionId:           parameters.azureSubscriptionId
				azureResourceGroupName:        parameters.azureResourceGroupName
				azureDnsZoneResourceGroupName: parameters.azureDnsZoneResourceGroupName
				azureDnsZoneName:              parameters.azureDnsZoneName
				relativeRecordSetName:         parameters.relativeRecordSetName
				azureCnameRecordTtl:           parameters.azureCnameRecordTtl
			}
		}, {
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
		}, {
			pattern: publishSite.DesignPattern
			pipelineParams: {
				repositoryKind: pipelineParameters.repositoryKind
				useSshKey:      pipelineParameters.useSshKey
			}
		},
	]
	pipelines: {}
}
