package webAppInfrastructure

import (
	"qmonus.net/adapter/official/pulumi/provider:kubernetes"
	"qmonus.net/adapter/official/pulumi/provider:azure"
	"qmonus.net/adapter/official/pulumi/provider:azureclassic"
	"qmonus.net/adapter/official/pulumi/provider:random"
	"qmonus.net/adapter/official/adapters/azure/component:azureApplicationGateway"
	"qmonus.net/adapter/official/adapters/azure/component:azureCacheForRedis"
	"qmonus.net/adapter/official/adapters/azure/component:azureCertManager"
	"qmonus.net/adapter/official/adapters/azure/component:azureContainerRegistry"
	"qmonus.net/adapter/official/adapters/azure/component:azureDatabaseForMysql"
	"qmonus.net/adapter/official/adapters/azure/component:azureDnsZone"
	"qmonus.net/adapter/official/adapters/azure/component:azureExternalSecrets"
	"qmonus.net/adapter/official/adapters/azure/component:azureKeyVault"
	"qmonus.net/adapter/official/adapters/azure/component:azureKubernetesService"
	"qmonus.net/adapter/official/adapters/azure/component:azurePublicIpAddress"
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
		dnsZoneName:            string
		kubernetesVersion:      string | *null
		kubernetesSkuTier:      "Standard" | *"Free"
		kubernetesNodeVmSize:   string | *"Standard_B2s"
		kubernetesNodeCount:    string | *"1"
		kubernetesOsDiskGb:     string | *"32"
		certmanagerVersion:     string | *"1.11.4"
		esoVersion:             string | *"0.9.0"
		keyVaultAccessAllowedObjectIds: [...string]
	}

	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
		{
			pattern: kubernetes.DesignPattern
			params: {
				providerName: "K8sProvider"
			}
		},
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
			pattern: azureApplicationGateway.DesignPattern
			params: {
				appName:             parameters.appName
				azureSubscriptionId: parameters.azureSubscriptionId
			}
		},
		{
			pattern: azureCacheForRedis.DesignPattern
			params: {
				appName: parameters.appName
			}
		},
		{
			pattern: azureCertManager.DesignPattern
			params: {
				appName:             parameters.appName
				azureSubscriptionId: parameters.azureSubscriptionId
				certmanagerVersion:  parameters.certmanagerVersion
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
			pattern: azureExternalSecrets.DesignPattern
			params: {
				appName:       parameters.appName
				azureTenantId: parameters.azureTenantId
				esoVersion:    parameters.esoVersion
			}
		},
		{
			pattern: azureKeyVault.DesignPattern
			params: {
				keyVaultAccessAllowedObjectIds: parameters.keyVaultAccessAllowedObjectIds
			}
		},
		{
			pattern: azureKubernetesService.DesignPattern
			params: {
				appName:              parameters.appName
				azureSubscriptionId:  parameters.azureSubscriptionId
				kubernetesVersion:    parameters.kubernetesVersion
				kubernetesSkuTier:    parameters.kubernetesSkuTier
				kubernetesNodeVmSize: parameters.kubernetesNodeVmSize
				kubernetesNodeCount:  parameters.kubernetesNodeCount
				kubernetesOsDiskGb:   parameters.kubernetesOsDiskGb
			}
		},
		{
			pattern: azurePublicIpAddress.DesignPattern
			params: {
				appName: parameters.appName
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
				appName: parameters.appName
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
				importStackName:   ""
				useBastionSshCred: false
			}
		},
	]

	resources: app: {
		"K8sProvider": {
			properties: {
				kubeconfig:        "${kubernetesCluster.kubeConfigRaw}"
				deleteUnreachable: true
			}
		}
	}

	pipelines: _
}
