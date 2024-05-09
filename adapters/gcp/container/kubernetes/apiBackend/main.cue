package apiBackend

import (
	"strconv"
	"strings"
	"list"

	"qmonus.net/adapter/official/adapters:utils"
	"qmonus.net/adapter/official/types:base"
	"qmonus.net/adapter/official/types:gcp"
	"qmonus.net/adapter/official/types:kubernetes"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/pipeline/build:buildkitGcp"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                                       string
		gcpProjectId:                                  string
		dnsZoneProjectId:                              string
		dnsZoneName:                                   string
		dnsARecordSubdomain:                           strings.HasSuffix(".")
		mysqlInstanceId?:                              string
		mysqlDatabaseName?:                            string
		mysqlUserName?:                                string
		cloudArmorAllowedSourceIps:                    [...string] | *[]
		k8sNamespace:                                  string
		imageName:                                     string
		replicas:                                      string | *"1"
		portEnvironmentVariableName:                   string | *"PORT"
		port:                                          string
		mysqlInstanceIpAddressEnvironmentVariableName: string | *"DB_HOST"
		mysqlInstanceIpAddress?:                       string
		mysqlUserNameEnvironmentVariableName:          string | *"DB_USER"
		mysqlUserPasswordEnvironmentVariableName:      string | *"DB_PASS"
		secrets: [string]:              base.#Secret
		environmentVariables: [string]: string
		args?: [...string]
	}

	pipelineParameters: {
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
		{
			pattern: buildkitGcp.DesignPattern
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
					gcp:        true
					aws:        false
					azure:      false
				}
				importStackName: ""
			}
		},
	]

	let _googleCloudProvider = "gcpProvider"
	let _resourceSuffix = "resourceSuffix"
	let _externalApplicationLoadBalancerIp = "externalApplicationLoadBalancerIp"
	let _aRecord = "aRecord"
	let _mysqlDatabase = "mysqlDatabase"
	let _mysqlUser = "mysqlUser"
	let _mysqlUserPassword = "mysqlUserPassword"
	let _mysqlUserNameSecret = "mysqlUserNameSecret"
	let _mysqlUserNameSecretVersion = "mysqlUserNameSecretVersion"
	let _mysqlUserPasswordSecret = "mysqlUserPasswordSecret"
	let _mysqlUserPasswordSecretVersion = "mysqlUserPasswordSecretVersion"
	let _cloudArmorPolicy = "cloudArmorPolicy"
	let _managedCertificate = "managedCertificate"
	let _backendConfig = "backendConfig"
	let _externalSecret = "externalSecret"
	let _deployment = "deployment"
	let _service = "service"
	let _ingress = "ingress"
	let _useMySQL = (parameters.mysqlInstanceIpAddress != _|_)
	let _useExternalSecret = _useMySQL || len(parameters.secrets) > 0

	parameters: #resourceId: {
		gcpProvider:                       _googleCloudProvider
		resourceSuffix:                    _resourceSuffix
		externalApplicationLoadBalancerIp: _externalApplicationLoadBalancerIp
		aRecord:                           _aRecord
		mysqlDatabase:                     _mysqlDatabase
		mysqlUser:                         _mysqlUser
		mysqlUserPassword:                 _mysqlUserPassword
		mysqlUserNameSecret:               _mysqlUserNameSecret
		mysqlUserNameSecretVersion:        _mysqlUserNameSecretVersion
		mysqlUserPasswordSecret:           _mysqlUserPasswordSecret
		mysqlUserPasswordSecretVersion:    _mysqlUserPasswordSecretVersion
		cloudArmorPolicy:                  _cloudArmorPolicy
		managedCertificate:                _managedCertificate
		backendConfig:                     _backendConfig
		externalSecret:                    _externalSecret
		deployment:                        _deployment
		service:                           _service
		ingress:                           _ingress
	}

	resources: app: {
		_#envVar: {
			name:  string
			value: string
		}
		_#env: [..._#envVar]

		_#externalSecretData: {
			secretKey: string
			remoteRef: {
				base.#Secret
			}
		}
		_#externalSecretDataList: [..._#externalSecretData]

		_gcpProvider: provider: "${\(_googleCloudProvider)}"

		"\(_googleCloudProvider)": gcp.#GcpProvider & {
			properties: {
				project: parameters.gcpProjectId
			}
		}

		"\(_resourceSuffix)": random.#RandomString & {
			properties: {
				length:  3
				special: false
				upper:   false
			}
		}

		"\(_externalApplicationLoadBalancerIp)": gcp.#GcpGlobalIpAddress & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 49}}.out
				name: "qvs-\(_appName)-lb-ip-${\(_resourceSuffix).result}"
			}
		}

		"\(_aRecord)": gcp.#GcpCloudDnsRecordSet & {
			properties: {
				project:     parameters.dnsZoneProjectId
				managedZone: parameters.dnsZoneName
				name:        parameters.dnsARecordSubdomain
				type:        "A"
				ttl:         3600
				rrdatas: [
					"${\(_externalApplicationLoadBalancerIp).address}",
				]
			}
		}

		if _useMySQL {
			"\(_mysqlDatabase)": gcp.#GcpCloudSqlDatabase & {
				options: _gcpProvider
				properties: {
					instance: parameters.mysqlInstanceId
					name:     parameters.mysqlDatabaseName
					charset:  "utf8mb4"
				}
			}

			"\(_mysqlUser)": gcp.#GcpCloudSqlUser & {
				options: _gcpProvider
				properties: {
					instance: parameters.mysqlInstanceId
					name:     parameters.mysqlUserName
					host:     "%"
					password: "${\(_mysqlUserPassword).result}"
				}
			}

			"\(_mysqlUserPassword)": random.#RandomPassword & {
				properties: {
					length:     16
					minLower:   1
					minUpper:   1
					minNumeric: 1
					special:    false
				}
			}

			"\(_mysqlUserNameSecret)": gcp.#GcpSecretManagerSecret & {
				options: _gcpProvider
				properties: {
					replication: {
						auto: {}
					}
					secretId: "qvs-\(parameters.appName)-mysql-user-name-${\(_resourceSuffix).result}"
				}
			}

			"\(_mysqlUserNameSecretVersion)": gcp.#GcpSecretManagerSecretVersion & {
				options: _gcpProvider
				properties: {
					secret: "${\(_mysqlUserNameSecret).id}"
					secretData: {
						"fn::secret": "${\(_mysqlUser).name}"
					}
				}
			}

			"\(_mysqlUserPasswordSecret)": gcp.#GcpSecretManagerSecret & {
				options: _gcpProvider
				properties: {
					replication: {
						auto: {}
					}
					secretId: "qvs-\(parameters.appName)-mysql-user-password-${\(_resourceSuffix).result}"
				}
			}

			"\(_mysqlUserPasswordSecretVersion)": gcp.#GcpSecretManagerSecretVersion & {
				options: _gcpProvider
				properties: {
					secret: "${\(_mysqlUserPasswordSecret).id}"
					secretData: {
						"fn::secret": "${\(_mysqlUserPassword).result}"
					}
				}
			}
		}

		"\(_cloudArmorPolicy)": gcp.#GcpCloudArmorPolicy & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 48}}.out
				name: "qvs-\(_appName)-policy-${\(_resourceSuffix).result}"
				let _numberOfAllowedSourceIps = len(parameters.cloudArmorAllowedSourceIps)
				if _numberOfAllowedSourceIps == 0 {
					rules: [
						{
							action:      "allow"
							description: "Managed by Qmonus Value Stream"
							priority:    2147483647
							match: {
								versionedExpr: "SRC_IPS_V1"
								config: {
									srcIpRanges: [
										"*",
									]
								}
							}
						},
					]
				}
				if _numberOfAllowedSourceIps > 0 {

					// Cloud Armor allows up to 10 IPs in a single rule.
					// if there are more than 10 IPs, the rule is divided and configured.
					// see https://cloud.google.com/armor/quotas#limits
					let _maximumNumberOfIpRanges = 10
					#rules: [ for _startIndex in list.Range(0, _numberOfAllowedSourceIps, _maximumNumberOfIpRanges) {
						{
							action:      "allow"
							description: "Managed by Qmonus Value Stream"
							priority:    2000 + _startIndex
							match: {
								versionedExpr: "SRC_IPS_V1"
								config: srcIpRanges: [

									// configure 10 IPs from the list of IPs to the rule.
									if _startIndex+_maximumNumberOfIpRanges < _numberOfAllowedSourceIps {
										list.Slice(parameters.cloudArmorAllowedSourceIps, _startIndex, _startIndex+_maximumNumberOfIpRanges)
									},

									// configure the remaining IPs from the list of IPs to the rule.
									list.Slice(parameters.cloudArmorAllowedSourceIps, _startIndex, _numberOfAllowedSourceIps),
								][0]
							}
						}
					}]
					#additionalRules: [...]
					#denyRule: [{
						action:      "deny(404)"
						description: "Managed by Qmonus Value Stream"
						priority:    2147483647
						match: {
							versionedExpr: "SRC_IPS_V1"
							config: {
								srcIpRanges: [
									"*",
								]
							}
						}
					}]
					rules: #rules + #additionalRules + #denyRule
				}
			}

		}

		"\(_managedCertificate)": kubernetes.#K8sManagedCertificate & {
			options: {
				dependsOn: [
					"${\(_aRecord)}",
				]
			}
			properties: {
				metadata: {
					name:      "\(parameters.appName)-cert"
					namespace: parameters.k8sNamespace
				}
				spec: {
					domains: [
						strings.TrimSuffix(parameters.dnsARecordSubdomain, "."),
					]
				}
			}
		}

		"\(_backendConfig)": kubernetes.#K8sBackendConfig & {
			properties: {
				metadata: {
					name:      "\(parameters.appName)-config"
					namespace: parameters.k8sNamespace
				}
				spec: {
					securityPolicy: {
						name: "${\(_cloudArmorPolicy).name}"
					}
				}
			}
		}

		let _secretName = "\(parameters.appName)-secret"
		if _useExternalSecret {
			"\(_externalSecret)": kubernetes.#K8sExternalSecret & {
				if _useMySQL {
					options: {
						dependsOn: [
							"${\(_mysqlUserNameSecretVersion)}",
							"${\(_mysqlUserPasswordSecretVersion)}",
						]
					}
				}
				properties: {
					metadata: {
						name:      "\(parameters.appName)-external-secret"
						namespace: parameters.k8sNamespace
					}
					spec: {
						refreshInterval: "0"
						secretStoreRef: {
							name: "qvs-global-gcp-store"
							kind: "ClusterSecretStore"
						}
						target: {
							name:           _secretName
							creationPolicy: "Owner"
						}

						_mysqlSecrets: [...]
						_userSecrets: [...]
						if _useMySQL {
							_mysqlSecrets: _#externalSecretDataList & [
									{
									secretKey: parameters.mysqlUserNameEnvironmentVariableName
									remoteRef: {
										key:     "${\(_mysqlUserNameSecret).secretId}"
										version: "latest"
									}
								},
								{
									secretKey: parameters.mysqlUserPasswordEnvironmentVariableName
									remoteRef: {
										key:     "${\(_mysqlUserPasswordSecret).secretId}"
										version: "latest"
									}
								},
							]
						}
						if len(parameters.secrets) > 0 {
							_userSecrets: _#externalSecretDataList & [
									for k, v in parameters.secrets {
									{
										secretKey: k
										remoteRef: {
											key:     v.key
											version: v.version
										}
									}
								},
							]
						}
						let _dataUnsorted = _mysqlSecrets + _userSecrets

						// sort to make results deterministic
						data: list.Sort(_dataUnsorted, {x: {}, y: {}, less: x.secretKey < y.secretKey})
					}
				}
			}
		}

		let _labelName = strings.Join([{utils.#trim & {str: parameters.appName, limit: 58}}.out, "apps"], "-")
		"\(_deployment)": kubernetes.#K8sDeployment & {
			if _useExternalSecret {
				options: {
					dependsOn: [
						"${\(_externalSecret)}",
					]
				}
			}
			properties: {
				metadata: {
					// take into account length of replicaset and pod name random suffix
					let _appName = {utils.#trim & {str: parameters.appName, limit: 42}}.out
					name:      "\(_appName)-apps"
					namespace: parameters.k8sNamespace
				}
				spec: {
					minReadySeconds: int | *60
					replicas:        strconv.Atoi(parameters.replicas)
					selector: matchLabels: {
						app: _labelName
					}
					template: {
						metadata: labels: {
							app: _labelName
						}
						spec: {
							terminationGracePeriodSeconds: int | *60
							containers: [
								{
									let _appName = {utils.#trim & {str: parameters.appName, limit: 59}}.out
									name:  "\(_appName)-app"
									image: parameters.imageName

									let _envUnsorted = _#env & [
										{
											name:  parameters.portEnvironmentVariableName
											value: parameters.port
										},
										if _useMySQL {
											{
												name:  parameters.mysqlInstanceIpAddressEnvironmentVariableName
												value: parameters.mysqlInstanceIpAddress
											}
										},
										for k, v in parameters.environmentVariables {
											{
												name:  k
												value: v
											}
										},
									]

									// sort to make results deterministic
									env: list.Sort(_envUnsorted, {x: {}, y: {}, less: x.name < y.name})
									if _useExternalSecret {
										envFrom: [
											{
												secretRef: name: _secretName
											},
										]
									}
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

		"\(_service)": kubernetes.#K8sService & {
			properties: {
				metadata: {
					let _appName = {utils.#trim & {str: parameters.appName, limit: 55}}.out
					name:      "qvs-\(_appName)-svc"
					namespace: parameters.k8sNamespace
					annotations: {
						"cloud.google.com/neg":            '{"ingress": true}'
						"cloud.google.com/backend-config": '{"default": "${\(_backendConfig).metadata.name}"}'
					}
				}
				spec: {
					type: "NodePort"
					ports: [{
						port:       80
						targetPort: strconv.Atoi(parameters.port)
					}]
					selector: {
						app: _labelName
					}
				}
			}
		}

		"\(_ingress)": kubernetes.#K8sIngress & {
			properties: {
				metadata: {
					let _appName = {utils.#trim & {str: parameters.appName, limit: 51}}.out
					name:      "qvs-\(_appName)-ingress"
					namespace: parameters.k8sNamespace
					annotations: {
						"kubernetes.io/ingress.class":                 "gce"
						"kubernetes.io/ingress.global-static-ip-name": "${\(_externalApplicationLoadBalancerIp).name}"
						"kubernetes.io/ingress.allow-http":            "false"
						"networking.gke.io/managed-certificates":      "${\(_managedCertificate).metadata.name}"
					}
				}
				spec: {
					rules: [
						{
							host: strings.TrimSuffix(parameters.dnsARecordSubdomain, ".")
							http: {
								paths: [{
									path:     "/*"
									pathType: "ImplementationSpecific"
									backend: {
										service: {
											name: "${\(_service).metadata.name}"
											port: {
												number: 80
											}
										}
									}
								}]
							}
						},
					]
				}
			}
		}
	}

	pipelines: _
}
