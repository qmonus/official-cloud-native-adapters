package apiBackend

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:base"
	"qmonus.net/adapter/official/types:kubernetes"
	"qmonus.net/adapter/official/types:mysql"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/pipeline/build:buildkitAzure"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"

	"strconv"
	"list"
)

DesignPattern: {
	parameters: {
		appName:                                string
		azureSubscriptionId:                    string
		azureResourceGroupName:                 string
		azureDnsZoneResourceGroupName:          string
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
		secrets: [string]:              base.#Secret
		environmentVariables: [string]: string
		args?: [...string]
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

	let _azureProvider = "AzureProvider"
	let _k8sProvider = "K8sProvider"
	let _mysqlProvider = "MysqlProvider"
	let _aRecord = "aRecord"
	let _database = "database"
	let _user = "user"
	let _grant = "grant"
	let _dbUserSecret = "dbUserSecret"
	let _dbPasswordSecret = "dbPasswordSecret"
	let _dbRandomPassword = "dbRandomPassword"
	let _ingress = "ingress"
	let _service = "service"
	let _deployment = "deployment"
	let _externalSecret = "externalSecret"
	let _secretName = "\(parameters.appName)-application-secret"

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
				resourceGroupName:     parameters.azureDnsZoneResourceGroupName
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

		#envData: {
			name:  string
			value: string
		}

		let _envData = [
			for n, v in parameters.environmentVariables {
				#envData & {
					name:  n
					value: v
				}
			},
		]
		_envElems: [...#envData] &
			_envData+[{
				name:  parameters.portEnvironmentVariableName
				value: parameters.port
			}, {
				name:  parameters.dbHostEnvironmentVariableName
				value: parameters.dbHost
			}, {
				name:  parameters.redisHostEnvironmentVariableName
				value: parameters.redisHost
			}, {
				name:  parameters.redisPortEnvironmentVariableName
				value: parameters.redisPort
			}]

		_envSet: [string]: #envData
		_envSet: {
			for e in _envElems {
				"\(e.name)": e
			}
		}

		_uniqEnvData: [ for s in _envSet {s}]
		// sort with name to make results deterministic
		let _envDataSorted = list.Sort(_uniqEnvData, {x: {}, y: {}, less: x.name < y.name})

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
									env:   _envDataSorted
									envFrom: [
										{
											secretRef: name: _secretName
										},
									]
									ports: [{
										containerPort: strconv.Atoi(parameters.port)
									}, ...]
									if parameters.args != _|_ {
										args: parameters.args
									}
								},
							]
						}
					}
				}
			}
		}

		#secretData: {
			secretKey: string
			remoteRef: {
				base.#Secret
			}
		}

		let _secretData = [
			for name, s in parameters.secrets {
				#secretData & {
					secretKey: name
					remoteRef: {
						key:     s.key
						version: s.version
					}
				}
			},
		]

		_secretElems: [...#secretData] &
			_secretData+[{
				secretKey: parameters.dbUserEnvironmentVariableName
				remoteRef: {
					key: parameters.azureKeyVaultDbUserSecretName
				}
			}, {
				secretKey: parameters.dbPasswordEnvironmentVariableName
				remoteRef: {
					key: parameters.azureKeyVaultDbPasswordSecretName
				}
			}, {
				secretKey: parameters.redisPasswordEnvironmentVariableName
				remoteRef: {
					key: parameters.redisPasswordSecretName
				}
			}]

		_secretSet: [string]: #secretData
		_secretSet: {
			for e in _secretElems {
				"\(e.secretKey)": e
			}
		}

		_uniqSecretData: [ for s in _secretSet {s}]

		// sort with secretKey to make results deterministic
		let _secretDataSorted = list.Sort(_uniqSecretData, {x: {}, y: {}, less: x.secretKey < y.secretKey})

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
						name:           _secretName
						creationPolicy: "Owner"
					}
					data: _secretDataSorted
				}
			}
		}
	}

	pipelines: _
}
