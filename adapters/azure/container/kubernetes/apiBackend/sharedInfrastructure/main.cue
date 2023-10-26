package sharedInfrastructure

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:kubernetes"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/adapters/azure/component:azureApplicationGateway"
	"qmonus.net/adapter/official/adapters/azure/component:azureCacheForRedis"
	"qmonus.net/adapter/official/adapters/azure/component:azureCertManager"
	"qmonus.net/adapter/official/adapters/azure/component:azureContainerRegistry"
	"qmonus.net/adapter/official/adapters/azure/component:azureDatabaseForMysql"
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
		appName:                       string
		azureTenantId:                 string
		azureSubscriptionId:           string
		azureResourceGroupName:        string
		azureDnsZoneResourceGroupName: string
		mysqlSkuName:                  string | *"B_Standard_B2s"
		mysqlVersion:                  string | *"8.0.21"
		dnsZoneName:                   string
		kubernetesVersion:             string | *null
		kubernetesSkuTier:             "Standard" | *"Free"
		kubernetesNodeVmSize:          string | *"Standard_B2s"
		kubernetesNodeCount:           string | *"1"
		kubernetesOsDiskGb:            string | *"32"
		certmanagerVersion:            string | *"1.11.4"
		esoVersion:                    string | *"0.9.0"
		keyVaultAccessAllowedObjectIds: [...string]
	}

	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
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
				appName:                       parameters.appName
				dnsZoneName:                   parameters.dnsZoneName
				azureDnsZoneResourceGroupName: parameters.azureDnsZoneResourceGroupName
				azureSubscriptionId:           parameters.azureSubscriptionId
				certmanagerVersion:            parameters.certmanagerVersion
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

	let _azureProvider = "AzureProvider"
	let _azureClassicProvider = "AzureClassicProvider"
	let _k8sProvider = "K8sProvider"
	let _randomProvider = "RandomProvider"
	let _kubernetesCluster = "kubernetesCluster"

	parameters: #resourceId: {
		azureProvider:        _azureProvider
		azureClassicProvider: _azureClassicProvider
		k8sProvider:          _k8sProvider
		randomProvider:       _randomProvider
		kubernetesCluster:    _kubernetesCluster
	}

	resources: app: {
		"\(_azureProvider)": azure.#AzureProvider

		"\(_azureClassicProvider)": azure.#AzureClassicProvider

		"\(_k8sProvider)": kubernetes.#K8sProvider & {
			properties: {
				kubeconfig:        "${\(_kubernetesCluster).kubeConfigRaw}"
				deleteUnreachable: true
			}
		}

		"\(_randomProvider)": random.#RandomProvider
	}

	pipelines: _
}
