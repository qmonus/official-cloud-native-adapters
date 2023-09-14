package azureApiBackendApplicationAdapter

import (
	"qmonus.net/adapter/official/pulumi/azure/sample:azureApiBackendApplicationAdapterForAzureResources"
	"qmonus.net/adapter/official/pulumi/azure/sample:azureApiBackendApplicationAdapterForKubernetesResources"
	"qmonus.net/adapter/official/pulumi/provider:azure"
	"qmonus.net/adapter/official/pulumi/provider:azureclassic"
	"qmonus.net/adapter/official/pulumi/provider:kubernetes"
	"qmonus.net/adapter/official/pulumi/provider:mysql"
	"qmonus.net/adapter/official/pulumi/provider:random"
	"qmonus.net/adapter/official/pipeline/build:buildkitAzure"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	name: "azure:azureApiBackendApplicationAdapter"

	parameters: {
		// common parameters derived from multiple adapters
		appName:                           string
		azureKeyVaultDbUserSecretName:     string | *"dbuser"
		azureKeyVaultDbPasswordSecretName: string | *"dbpassword"

		// derived from azureApiBackendApplicationAdapterForAzureResources
		azureSubscriptionId:           string
		azureResourceGroupName:        string
		azureDnsZoneName:              string
		azureDnsARecordName:           string
		azureStaticIpAddress:          string
		mysqlCreateUserName:           string | *"dbuser"
		mysqlCreateDbName:             string
		mysqlEndpoint:                 string | *parameters.dbHost
		azureKeyVaultKeyContainerName: string

		// derived from azureApiBackendApplicationAdapterForKubernetesResources
		clusterIssuerName:       string
		k8sNamespace:            string
		imageName:               string
		port:                    string
		dbHost:                  string
		redisHost:               string
		redisPasswordSecretName: string
		host:                    string
	}

	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
		{
			pattern: azureApiBackendApplicationAdapterForAzureResources.DesignPattern
			params: {
				appName:                                parameters.appName
				azureSubscriptionId:                    parameters.azureSubscriptionId
				azureResourceGroupName:                 parameters.azureResourceGroupName
				azureDnsZoneName:                       parameters.azureDnsZoneName
				azureDnsARecordName:                    parameters.azureDnsARecordName
				azureStaticIpAddress:                   parameters.azureStaticIpAddress
				azureARecordTtl:                        "3600"
				mysqlCreateUserName:                    parameters.mysqlCreateUserName
				mysqlCreateDbName:                      parameters.mysqlCreateDbName
				mysqlCreateDbCharacterSet:              "utf8mb3"
				mysqlEndpoint:                          parameters.mysqlEndpoint
				azureKeyVaultKeyContainerName:          parameters.azureKeyVaultKeyContainerName
				azureKeyVaultDbAdminSecretName:         "dbadminuser"
				azureKeyVaultDbAdminPasswordSecretName: "dbadminpassword"
				azureKeyVaultDbUserSecretName:          parameters.azureKeyVaultDbUserSecretName
				azureKeyVaultDbPasswordSecretName:      parameters.azureKeyVaultDbPasswordSecretName
			}
		},
		{
			pattern: azureApiBackendApplicationAdapterForKubernetesResources.DesignPattern
			params: {
				appName:                              parameters.appName
				clusterIssuerName:                    parameters.clusterIssuerName
				k8sNamespace:                         parameters.k8sNamespace
				imageName:                            parameters.imageName
				replicas:                             "1"
				portEnvironmentVariableName:          "PORT"
				port:                                 parameters.port
				dbHostEnvironmentVariableName:        "DB_HOST"
				dbHost:                               parameters.dbHost
				dbUserEnvironmentVariableName:        "DB_USER"
				azureKeyVaultDbUserSecretName:        parameters.azureKeyVaultDbUserSecretName
				dbPasswordEnvironmentVariableName:    "DB_PASS"
				azureKeyVaultDbPasswordSecretName:    parameters.azureKeyVaultDbPasswordSecretName
				redisHostEnvironmentVariableName:     "REDIS_HOST"
				redisHost:                            parameters.redisHost
				redisPortEnvironmentVariableName:     "REDIS_PORT"
				redisPort:                            "6380"
				redisPasswordEnvironmentVariableName: "REDIS_PASS"
				redisPasswordSecretName:              parameters.redisPasswordSecretName
				host:                                 parameters.host
				clusterSecretStoreName:               "qvs-global-azure-store"
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
			pattern: kubernetes.DesignPattern
			params: {
				providerName: "K8sProvider"
			}
		},
		{
			pattern: mysql.DesignPattern
			params: {
				providerName: "MysqlProvider"
			}
		},
		{
			pattern: random.DesignPattern
			params: {
				providerName: "RandomProvider"
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
				repositoryKind:       pipelineParameters.repositoryKind
				useDebug:             false
				deployPhase:          "app"
				resourcePriority:     "medium"
				useSshKey:            pipelineParameters.useSshKey
				pulumiCredentialName: "qmonus-pulumi-secret"
				useCred: {
					kubernetes: true
					gcp:        false
					aws:        false
					azure:      true
				}
				importStackName: ""
			}
		},
	]

	resources: {
		app: {
			"certificate/\(parameters.appName)": options: dependsOn: [
				"${aRecord/\(parameters.appName)}",
			]
			"secret/\(parameters.appName)": options: dependsOn: [
				"${dbUserSecret/\(parameters.appName)}",
				"${dbPasswordSecret/\(parameters.appName)}",
			]
		}
	}

	pipelines: _
}
