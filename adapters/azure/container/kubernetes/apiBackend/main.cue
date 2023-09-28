package apiBackend

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:kubernetes"
	"qmonus.net/adapter/official/types:mysql"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/pipeline/build:buildkitAzure"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"

	"strconv"
)

DesignPattern: {
	parameters: {
		appName:                                string
		azureSubscriptionId:                    string
		azureResourceGroupName:                 string
		azureDnsZoneName:                       string
		azureDnsARecordName:                    string
		azureStaticIpAddress:                   string
		azureARecordTtl:                        string | *"3600"
		mysqlCreateUserName:                    string | *"dbuser"
		mysqlCreateDbName:                      string
		mysqlCreateDbCharacterSet:              string | *"utf8mb3"
		mysqlEndpoint:                          string | *parameters.dbHost
		azureKeyVaultKeyContainerName:          string
		azureKeyVaultDbAdminSecretName:         string | *"dbadminuser"
		azureKeyVaultDbAdminPasswordSecretName: string | *"dbadminpassword"
		azureKeyVaultDbUserSecretName:          string | *"dbuser"
		azureKeyVaultDbPasswordSecretName:      string | *"dbpassword"
		clusterIssuerName:                      string
		k8sNamespace:                           string
		imageName:                              string
		replicas:                               string | *"1"
		portEnvironmentVariableName:            string | *"PORT"
		port:                                   string
		dbHostEnvironmentVariableName:          string | *"DB_HOST"
		dbHost:                                 string
		dbUserEnvironmentVariableName:          string | *"DB_USER"
		dbPasswordEnvironmentVariableName:      string | *"DB_PASS"
		redisHostEnvironmentVariableName:       string | *"REDIS_HOST"
		redisHost:                              string
		redisPortEnvironmentVariableName:       string | *"REDIS_PORT"
		redisPort:                              *"6380" | "6379"
		redisPasswordEnvironmentVariableName:   string | *"REDIS_PASS"
		redisPasswordSecretName:                string
		host:                                   string
		clusterSecretStoreName:                 string | *"qvs-global-azure-store"
	}

	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
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

	let _azureProvider = "AzureProvider_apiBackend"
	let _k8sProvider = "K8sProvider_apiBackend"
	let _mysqlProvider = "MysqlProvider_apiBackend"
	let _aRecord = "AzureDnsRecordSet_aRecord"
	let _database = "MysqlDatabase_apiBackend"
	let _user = "MysqlUser_apiBackend"
	let _grant = "MysqlGrant_apiBackend"
	let _dbUserSecret = "AzureKeyVaultSecret_user"
	let _dbPasswordSecret = "AzureKeyVaultSecret_password"
	let _dbRandomPassword = "RandomPassword_apiBackend"
	let _ingress = "K8sIngress_apiBackend"
	let _service = "K8sService_apiBackend"
	let _deployment = "K8sDeployment_apiBackend"
	let _externalSecret = "K8sExternalSecret_apiBackend"

	parameters: #resourceId: {
		azureProvider:    _azureProvider
		k8sProvider:      _k8sProvider
		mysqlProvider:    _mysqlProvider
		aRecord:          _aRecord
		database:         _database
		user:             _user
		grant:            _grant
		dbUserSecret:     _dbUserSecret
		dbPasswordSecret: _dbPasswordSecret
		dbRandomPassword: _dbRandomPassword
		ingress:          _ingress
		service:          _service
		deployment:       _deployment
		externalSecret:   _externalSecret
	}

	resources: app: {
		"\(_azureProvider)": azure.#AzureProvider

		"\(_k8sProvider)": kubernetes.#K8sProvider

		"\(_mysqlProvider)": mysql.#MysqlProvider & {
			properties: {
				endpoint: parameters.mysqlEndpoint
				username: {
					"fn::secret": {
						"fn::invoke": {
							function: "azure:keyvault:getSecret"
							arguments: {
								name:       parameters.azureKeyVaultDbAdminSecretName
								keyVaultId: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/\(parameters.azureResourceGroupName)/providers/Microsoft.KeyVault/vaults/\(parameters.azureKeyVaultKeyContainerName)"
							}
							return: "value"
						}
					}
				}
				password: {
					"fn::secret": {
						"fn::invoke": {
							function: "azure:keyvault:getSecret"
							arguments: {
								name:       parameters.azureKeyVaultDbAdminPasswordSecretName
								keyVaultId: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/\(parameters.azureResourceGroupName)/providers/Microsoft.KeyVault/vaults/\(parameters.azureKeyVaultKeyContainerName)"
							}
							return: "value"
						}
					}
				}
				tls: "skip-verify"
			}
		}

		"\(_aRecord)": azure.#AzureDnsRecordSet & {
			options: provider: "${\(_azureProvider)}"
			properties: {
				recordType:            "A"
				resourceGroupName:     parameters.azureResourceGroupName
				zoneName:              parameters.azureDnsZoneName
				relativeRecordSetName: parameters.azureDnsARecordName
				aRecords: [{ipv4Address: parameters.azureStaticIpAddress}]
				ttl: strconv.Atoi(parameters.azureARecordTtl)
			}
		}

		"\(_database)": mysql.#MysqlDatabase & {
			options: provider: "${\(_mysqlProvider)}"
			properties: {
				name:                parameters.mysqlCreateDbName
				defaultCharacterSet: parameters.mysqlCreateDbCharacterSet
			}
		}

		"\(_user)": mysql.#MysqlUser & {
			options: provider: "${\(_mysqlProvider)}"
			properties: {
				user:              parameters.mysqlCreateUserName
				host:              "%"
				plaintextPassword: "${\(_dbRandomPassword).result}"
			}
		}

		"\(_grant)": mysql.#MysqlGrant & {
			options: {
				provider: "${\(_mysqlProvider)}"
				dependsOn: [
					"${\(_database)}",
					"${\(_user)}",
				]
			}
			properties: {
				database: parameters.mysqlCreateDbName
				user:     parameters.mysqlCreateUserName
				host:     "%"
				privileges: ["ALL"]
				table: "*"
			}
		}

		"\(_dbUserSecret)": azure.#AzureKeyVaultSecret & {
			options: provider: "${\(_azureProvider)}"
			properties: {
				properties: {
					value: parameters.mysqlCreateUserName
				}
				resourceGroupName: parameters.azureResourceGroupName
				vaultName:         parameters.azureKeyVaultKeyContainerName
				secretName:        parameters.azureKeyVaultDbUserSecretName
			}
		}

		"\(_dbPasswordSecret)": azure.#AzureKeyVaultSecret & {
			options: provider: "${\(_azureProvider)}"
			properties: {
				properties: {
					value: "${\(_dbRandomPassword).result}"
				}
				resourceGroupName: parameters.azureResourceGroupName
				vaultName:         parameters.azureKeyVaultKeyContainerName
				secretName:        parameters.azureKeyVaultDbPasswordSecretName
			}
		}

		"\(_dbRandomPassword)": random.#RandomPassword & {
			properties: {
				length:     16
				minLower:   1
				minUpper:   1
				minNumeric: 1
				special:    false
			}
		}

		"\(_ingress)": kubernetes.#K8sIngress & {
			options: provider: "${\(_k8sProvider)}"
			properties: {
				metadata: {
					name:      parameters.appName
					namespace: parameters.k8sNamespace
					annotations: {
						"cert-manager.io/private-key-rotation-policy": "Always"
						"kubernetes.io/ingress.class":                 "azure/application-gateway"
						"cert-manager.io/cluster-issuer":              parameters.clusterIssuerName
					}
				}
				spec: {
					rules: [
						{
							host: parameters.host
							http: {
								paths: [{
									path:     "/*"
									pathType: "ImplementationSpecific"
									backend: {
										service: {
											name: parameters.appName
											port: {
												number: 80
											}
										}
									}
								}]
							}
						},
					]
					tls: [
						{
							hosts: [parameters.host]
							secretName: "\(parameters.appName)-certificate-secret"
						},
					]
				}
			}
		}

		"\(_service)": kubernetes.#K8sService & {
			options: provider: "${\(_k8sProvider)}"
			properties: {
				metadata: {
					name:      parameters.appName
					namespace: parameters.k8sNamespace
				}
				spec: {
					type: "NodePort"
					ports: [{
						port:       80
						targetPort: strconv.Atoi(parameters.port)
					}]
					selector: {
						app: parameters.appName
					}
				}
			}
		}

		"\(_deployment)": kubernetes.#K8sDeployment & {
			options: {
				provider: "${\(_k8sProvider)}"
				dependsOn: ["${\(_externalSecret)}"]
			}
			properties: {
				metadata: {
					name:      parameters.appName
					namespace: parameters.k8sNamespace
					annotations: "vs.axis-dev.io/dependsOn": "external-secrets.io:ExternalSecret::\(parameters.k8sNamespace)/\(parameters.appName)"
				}
				spec: {
					minReadySeconds: int | *60
					replicas:        strconv.Atoi(parameters.replicas)
					selector: matchLabels: {
						app: parameters.appName
					}
					template: {
						metadata: labels: {
							app: parameters.appName
						}
						spec: {
							terminationGracePeriodSeconds: int | *60
							containers: [
								{
									name:  parameters.appName
									image: parameters.imageName
									env: [{
										name:  parameters.portEnvironmentVariableName
										value: parameters.port
									}, {
										name:  parameters.dbHostEnvironmentVariableName
										value: parameters.dbHost
									}, {
										name: parameters.dbUserEnvironmentVariableName
										valueFrom: secretKeyRef: {
											name: "\(parameters.appName)-application-secret"
											key:  parameters.azureKeyVaultDbUserSecretName
										}
									}, {
										name: parameters.dbPasswordEnvironmentVariableName
										valueFrom: secretKeyRef: {
											name: "\(parameters.appName)-application-secret"
											key:  parameters.azureKeyVaultDbPasswordSecretName
										}
									}, {
										name:  parameters.redisHostEnvironmentVariableName
										value: parameters.redisHost
									}, {
										name:  parameters.redisPortEnvironmentVariableName
										value: parameters.redisPort
									}, {
										name: parameters.redisPasswordEnvironmentVariableName
										valueFrom: secretKeyRef: {
											name: "\(parameters.appName)-application-secret"
											key:  parameters.redisPasswordSecretName
										}
									}]
									ports: [{
										containerPort: strconv.Atoi(parameters.port)
									}, ...]
								},
							]
						}
					}
				}
			}
		}
		"\(_externalSecret)": kubernetes.#K8sExternalSecret & {
			options: {
				provider: "${\(_k8sProvider)}"
				dependsOn: [
					"${\(_dbUserSecret)}",
					"${\(_dbPasswordSecret)}",
				]
			}
			properties: {
				metadata: {
					name:      parameters.appName
					namespace: parameters.k8sNamespace
				}
				spec: {
					refreshInterval: "0"
					secretStoreRef: {
						name: parameters.clusterSecretStoreName
						kind: "ClusterSecretStore"
					}
					target: {
						name:           "\(parameters.appName)-application-secret"
						creationPolicy: "Owner"
					}
					data: [{
						secretKey: parameters.azureKeyVaultDbUserSecretName
						remoteRef: {
							key: parameters.azureKeyVaultDbUserSecretName
						}
					}, {
						secretKey: parameters.azureKeyVaultDbPasswordSecretName
						remoteRef: {
							key: parameters.azureKeyVaultDbPasswordSecretName
						}
					}, {
						secretKey: parameters.redisPasswordSecretName
						remoteRef: {
							key: parameters.redisPasswordSecretName
						}
					}]
				}
			}
		}
	}

	pipelines: _
}
