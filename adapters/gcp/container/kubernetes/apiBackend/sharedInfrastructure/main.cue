package sharedInfrastructure

import (
	"strconv"
	"strings"

	"qmonus.net/adapter/official/adapters:utils"
	"qmonus.net/adapter/official/types:gcp"
	"qmonus.net/adapter/official/types:kubernetes"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                     string
		gcpProjectId:                string
		gkeReleaseChannel:           *"REGULAR" | "RAPID" | "STABLE" | "UNSPECIFIED"
		gkeMasterAuthorizedNetworks: [...string] | *[]
		gkeNodeAutoUpgrade:          *"true" | "false"
		gkeNodeVersion?:             string
		gkeNodeDiskSizeGb:           string | *"32"
		gkeNodeMachineType:          string | *"e2-medium"
		gkeNodeCount:                string | *"1"
		gkeNodeLocation:             string | *"asia-northeast1"
		esoVersion:                  string | *"0.9.9"
		mysqlCpuCount:               string | *"2"
		mysqlMemorySizeMb:           string | *"4096"
		mysqlDatabaseVersion:        strings.HasPrefix("MYSQL_") | *"MYSQL_8_0"
		mysqlAvailabilityType:       *"ZONAL" | "REGIONAL"
		useMySQL:                    *"true" | "false"
	}

	pipelineParameters: {
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
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
					gcp:        true
					aws:        false
					azure:      false
				}
				importStackName:   ""
				useBastionSshCred: false
			}
		},
	]

	let _googleCloudProvider = "gcpProvider"
	let _vpcNetwork = "vpcNetwork"
	let _subnet = "subnet"
	let _gkeCluster = "gkeCluster"
	let _gkeNodepool = "gkeNodepool"
	let _gkeNodepoolServiceAccount = "gkeNodepoolServiceAccount"
	let _gkeNodepoolServiceAccountIamMemberGarReader = "gkeNodepoolServiceAccountIamMemberGarReader"
	let _gkeNodepoolServiceAccountIamMemberLoggingLogWriter = "gkeNodepoolServiceAccountIamMemberLoggingLogWriter"
	let _gkeNodepoolServiceAccountIamMemberMonitoringMetricWriter = "gkeNodepoolServiceAccountIamMemberMonitoringMetricWriter"
	let _gkeKubeconfigSecret = "gkeKubeconfigSecret"
	let _gkeKubeconfigSecretVersion = "gkeKubeconfigSecretVersion"
	let _cloudNatIpAddress = "cloudNatIpAddress"
	let _cloudNatGateway = "cloudNatGateway"
	let _cloudNatRouter = "cloudNatRouter"
	let _kubernetesProvider = "k8sProvider"
	let _esoGcpServiceAccount = "esoGcpServiceAccount"
	let _esoGcpServiceAccountIamMemberSecretManagerSecretAccessor = "esoGcpServiceAccountIamMemberSecretManagerSecretAccessor"
	let _esoNamespace = "esoNamespace"
	let _esoK8sServiceAccount = "esoK8sServiceAccount"
	let _esoGcpServiceAccountIamPolicyBindingWorkloadIdentityUser = "esoGcpServiceAccountIamPolicyBindingWorkloadIdentityUser"
	let _eso = "eso"
	let _esoClusterSecretStore = "esoClusterSecretStore"
	let _artifactRegistry = "artifactRegistry"
	let _mysqlInstance = "mysqlInstance"
	let _mysqlRootUser = "mysqlRootUser"
	let _mysqlRootPassword = "mysqlRootPassword"
	let _mysqlRootPasswordSecret = "mysqlRootPasswordSecret"
	let _mysqlRootPasswordSecretVersion = "mysqlRootPasswordSecretVersion"

	let _useMySQL = strconv.ParseBool(parameters.useMySQL)

	parameters: #resourceId: {
		gcpProvider:                                              _googleCloudProvider
		vpcNetwork:                                               _vpcNetwork
		subnet:                                                   _subnet
		gkeCluster:                                               _gkeCluster
		gkeNodepool:                                              _gkeNodepool
		gkeNodepoolServiceAccount:                                _gkeNodepoolServiceAccount
		gkeNodepoolServiceAccountIamMemberGarReader:              _gkeNodepoolServiceAccountIamMemberGarReader
		gkeNodepoolServiceAccountIamMemberLoggingLogWriter:       _gkeNodepoolServiceAccountIamMemberLoggingLogWriter
		gkeNodepoolServiceAccountIamMemberMonitoringMetricWriter: _gkeNodepoolServiceAccountIamMemberMonitoringMetricWriter
		gkeKubeconfigSecret:                                      _gkeKubeconfigSecret
		gkeKubeconfigSecretVersion:                               _gkeKubeconfigSecretVersion
		cloudNatIpAddress:                                        _cloudNatIpAddress
		cloudNatGateway:                                          _cloudNatGateway
		cloudNatRouter:                                           _cloudNatRouter
		k8sProvider:                                              _kubernetesProvider
		esoGcpServiceAccount:                                     _esoGcpServiceAccount
		esoGcpServiceAccountIamMemberSecretManagerSecretAccessor: _esoGcpServiceAccountIamMemberSecretManagerSecretAccessor
		esoNamespace:                                             _esoNamespace
		esoK8sServiceAccount:                                     _esoK8sServiceAccount
		esoGcpServiceAccountIamPolicyBindingWorkloadIdentityUser: _esoGcpServiceAccountIamPolicyBindingWorkloadIdentityUser
		eso:                                                      _eso
		esoClusterSecretStore:                                    _esoClusterSecretStore
		artifactRegistry:                                         _artifactRegistry
		mysqlInstance:                                            _mysqlInstance
		mysqlRootUser:                                            _mysqlRootUser
		mysqlRootPassword:                                        _mysqlRootPassword
		mysqlRootPasswordSecret:                                  _mysqlRootPasswordSecret
		mysqlRootPasswordSecretVersion:                           _mysqlRootPasswordSecretVersion
	}

	resources: app: {
		_gcpProvider: provider: "${\(_googleCloudProvider)}"
		_k8sProvider: provider: "${\(_kubernetesProvider)}"

		"\(_googleCloudProvider)": gcp.#GcpProvider & {
			properties: {
				project: parameters.gcpProjectId
			}
		}

		"\(_vpcNetwork)": gcp.#GcpVpcNetwork & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 52}}.out
				autoCreateSubnetworks: false
				name:                  "qvs-\(_appName)-vpc-nw"
				routingMode:           "GLOBAL"
			}
		}

		"\(_subnet)": gcp.#GcpSubnet & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 52}}.out
				ipCidrRange:           "10.0.0.0/22"
				network:               "${\(_vpcNetwork).id}"
				name:                  "qvs-\(_appName)-subnet"
				privateIpGoogleAccess: true
				region:                "asia-northeast1"
				secondaryIpRanges: [
					{
						rangeName:   "gke-pod-range"
						ipCidrRange: "10.4.0.0/14"
					},
					{
						rangeName:   "gke-service-range"
						ipCidrRange: "10.0.24.0/22"
					},
				]
			}
		}

		"\(_gkeCluster)": gcp.#GcpGkeCluster & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 28}}.out
				addonsConfig: {
					dnsCacheConfig: {
						enabled: true
					}
					horizontalPodAutoscaling: {
						disabled: true
					}
				}
				deletionProtection: false
				initialNodeCount:   1
				ipAllocationPolicy: {
					clusterSecondaryRangeName:  "${\(_subnet).secondaryIpRanges[0].rangeName}"
					servicesSecondaryRangeName: "${\(_subnet).secondaryIpRanges[1].rangeName}"
				}
				if len(parameters.gkeMasterAuthorizedNetworks) > 0 {
					masterAuthorizedNetworksConfig: {
						cidrBlocks: [ for i in parameters.gkeMasterAuthorizedNetworks {
							cidrBlock:   "\(i)"
							displayName: "Managed by Qmonus Value Stream"
						}]
					}
				}
				location:       parameters.gkeNodeLocation
				name:           "qvs-\(_appName)-cluster"
				network:        "${\(_vpcNetwork).name}"
				networkingMode: "VPC_NATIVE"
				privateClusterConfig: {
					enablePrivateEndpoint: false
					enablePrivateNodes:    true
					masterIpv4CidrBlock:   "172.16.0.0/28"
				}
				releaseChannel: {
					channel: parameters.gkeReleaseChannel
				}
				removeDefaultNodePool: true
				subnetwork:            "${\(_subnet).name}"
				verticalPodAutoscaling: {
					enabled: false
				}
				workloadIdentityConfig: {
					workloadPool: "\(parameters.gcpProjectId).svc.id.goog"
				}
			}
		}

		"\(_gkeNodepool)": gcp.#GcpGkeNodepool & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 33}}.out
				cluster: "${\(_gkeCluster).id}"
				management: {
					autoRepair: true
					if parameters.gkeReleaseChannel == "UNSPECIFIED" {
						autoUpgrade: strconv.ParseBool(parameters.gkeNodeAutoUpgrade)
					}
					if parameters.gkeReleaseChannel != "UNSPECIFIED" {
						autoUpgrade: true
					}
				}
				maxPodsPerNode: 100
				name:           "qvs-\(_appName)-np"
				nodeConfig: {
					diskSizeGb:  strconv.Atoi(parameters.gkeNodeDiskSizeGb)
					diskType:    "pd-balanced"
					imageType:   "COS_CONTAINERD"
					machineType: parameters.gkeNodeMachineType
					metadata: {
						"disable-legacy-endpoints": true
					}
					serviceAccount: "${\(_gkeNodepoolServiceAccount).email}"
					workloadMetadataConfig: {
						mode: "GKE_METADATA"
					}
				}
				nodeCount: strconv.Atoi(parameters.gkeNodeCount)
				if parameters.gkeNodeVersion != _|_ {
					version: parameters.gkeNodeVersion
				}
			}
		}

		"\(_gkeNodepoolServiceAccount)": gcp.#GcpServiceAccount & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 23}}.out
				accountId:   "qvs-\(_appName)-np"
				displayName: "[Managed by Qmonus Value Stream] GKE Nodepool Service Account"
			}
		}

		"\(_gkeNodepoolServiceAccountIamMemberGarReader)": gcp.#GcpIamMember & {
			properties: {
				member:  "${\(_gkeNodepoolServiceAccount).member}"
				project: parameters.gcpProjectId
				role:    "roles/artifactregistry.reader"
			}
		}

		"\(_gkeNodepoolServiceAccountIamMemberLoggingLogWriter)": gcp.#GcpIamMember & {
			properties: {
				member:  "${\(_gkeNodepoolServiceAccount).member}"
				project: parameters.gcpProjectId
				role:    "roles/logging.logWriter"
			}
		}

		"\(_gkeNodepoolServiceAccountIamMemberMonitoringMetricWriter)": gcp.#GcpIamMember & {
			properties: {
				member:  "${\(_gkeNodepoolServiceAccount).member}"
				project: parameters.gcpProjectId
				role:    "roles/monitoring.metricWriter"
			}
		}

		"\(_gkeKubeconfigSecret)": gcp.#GcpSecretManagerSecret & {
			options: _gcpProvider
			properties: {
				replication: {
					auto: {}
				}
				secretId: "qvs-\(parameters.appName)-cluster-kubeconfig"
			}
		}

		let _kubeconfig = """
			apiVersion: v1
			clusters:
			- cluster:
			    certificate-authority-data: ${\(_gkeCluster).masterAuth["clusterCaCertificate"]}
			    server: https://${\(_gkeCluster).endpoint}
			  name: ${\(_gkeCluster).name}
			contexts:
			- context:
			    cluster: ${\(_gkeCluster).name}
			    user: ${\(_gkeCluster).name}
			  name: ${\(_gkeCluster).name}
			current-context: ${\(_gkeCluster).name}
			kind: Config
			preferences: {}
			users:
			- name: ${\(_gkeCluster).name}
			  user:
			    exec:
			      apiVersion: client.authentication.k8s.io/v1beta1
			      command: gke-gcloud-auth-plugin
			      installHint: Install gke-gcloud-auth-plugin for use with kubectl by following
			        https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
			      provideClusterInfo: true
			"""

		"\(_gkeKubeconfigSecretVersion)": gcp.#GcpSecretManagerSecretVersion & {
			options: _gcpProvider

			properties: {
				secret: "${\(_gkeKubeconfigSecret).id}"
				secretData: {
					"fn::secret": _kubeconfig
				}
			}
		}

		"\(_cloudNatIpAddress)": gcp.#GcpIpAddress & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 52}}.out
				name:   "qvs-\(_appName)-nat-ip"
				region: "${\(_subnet).region}"
			}
		}

		"\(_cloudNatGateway)": gcp.#GcpCloudNatGateway & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 52}}.out
				router:                        "${\(_cloudNatRouter).name}"
				sourceSubnetworkIpRangesToNat: "ALL_SUBNETWORKS_ALL_IP_RANGES"
				logConfig: {
					enable: true
					filter: "ERRORS_ONLY"
				}
				minPortsPerVm:       512
				name:                "qvs-\(_appName)-nat-gw"
				natIpAllocateOption: "MANUAL_ONLY"
				natIps: [
					"${\(_cloudNatIpAddress).selfLink}",
				]
				region: "${\(_cloudNatRouter).region}"
			}
		}

		"\(_cloudNatRouter)": gcp.#GcpCloudRouter & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 52}}.out
				network: "${\(_vpcNetwork).name}"
				name:    "qvs-\(_appName)-router"
				region:  "${\(_subnet).region}"
			}
		}

		"\(_kubernetesProvider)": kubernetes.#K8sProvider & {
			options: {
				dependsOn: [
					"${\(_gkeNodepool)}",
				]
			}
			properties: {
				kubeconfig: {
					"fn::secret": _kubeconfig
				}
				deleteUnreachable: true
			}
		}

		"\(_esoGcpServiceAccount)": gcp.#GcpServiceAccount & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 22}}.out
				accountId:   "qvs-\(_appName)-eso"
				displayName: "[Managed by Qmonus Value Stream] ESO Service Account for Workload Identity"
			}
		}

		"\(_esoGcpServiceAccountIamMemberSecretManagerSecretAccessor)": gcp.#GcpIamMember & {
			properties: {
				member:  "${\(_esoGcpServiceAccount).member}"
				project: parameters.gcpProjectId
				role:    "roles/secretmanager.secretAccessor"
			}
		}

		"\(_esoNamespace)": kubernetes.#K8sNamespace & {
			options: {
				_k8sProvider
				dependsOn: [
					"${\(_gkeCluster)}",
				]
			}
			properties: {
				metadata: {
					name: "external-secrets"
				}
			}
		}

		"\(_esoK8sServiceAccount)": kubernetes.#K8sServiceAccount & {
			options: _k8sProvider
			properties: {
				metadata: {
					name:      "qvs-eso-sa"
					namespace: "${\(_esoNamespace).metadata.name}"
					annotations: {
						"iam.gke.io/gcp-service-account": "${\(_esoGcpServiceAccount).email}"
					}
				}
			}
		}

		"\(_esoGcpServiceAccountIamPolicyBindingWorkloadIdentityUser)": gcp.#GcpServiceAccountIamBinding & {
			options: _gcpProvider
			properties: {
				serviceAccountId: "${\(_esoGcpServiceAccount).name}"
				role:             "roles/iam.workloadIdentityUser"
				members: [
					"serviceAccount:\(parameters.gcpProjectId).svc.id.goog[${\(_esoNamespace).metadata.name}/${\(_esoK8sServiceAccount).metadata.name}]",
				]
			}
		}

		"\(_eso)": kubernetes.#K8sHelmRelease & {
			options: {
				_k8sProvider
				dependsOn: [
					"${\(_esoGcpServiceAccountIamPolicyBindingWorkloadIdentityUser)}",
				]
			}
			properties: {
				chart:     "external-secrets"
				version:   "\(parameters.esoVersion)"
				namespace: "${\(_esoNamespace).metadata.name}"
				repositoryOpts: {
					repo: "https://charts.external-secrets.io"
				}
				values: {
					installCRDs: true
					serviceAccount: {
						create: false
						name:   "${\(_esoK8sServiceAccount).metadata.name}"
					}
				}
			}
		}

		"\(_esoClusterSecretStore)": kubernetes.#K8sClusterSecretStore & {
			options: {
				_k8sProvider
				dependsOn: [
					"${\(_eso)}",
				]
			}
			properties: {
				metadata: {
					name: "qvs-global-gcp-store"
				}
				spec: {
					provider: {
						gcpsm: {
							projectID: parameters.gcpProjectId
							auth: {
								workloadIdentity: {
									clusterLocation: "${\(_gkeCluster).location}"
									clusterName:     "${\(_gkeCluster).name}"
									serviceAccountRef: {
										name:      "${\(_esoK8sServiceAccount).metadata.name}"
										namespace: "${\(_esoNamespace).metadata.name}"
									}
								}
							}
						}
					}
				}
			}
		}

		"\(_artifactRegistry)": gcp.#GcpArtifactRegistry & {
			options: _gcpProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 50}}.out
				format:       "DOCKER"
				location:     "asia-northeast1"
				repositoryId: "qvs-\(_appName)-registry"
			}
		}
		if _useMySQL {
			"\(_mysqlInstance)": gcp.#GcpCloudSqlInstance & {
				options: _gcpProvider
				properties: {
					let _appName = {utils.#trim & {str: parameters.appName, limit: 66}}.out
					name:               "qvs-\(_appName)-mysql"
					region:             "asia-northeast1"
					databaseVersion:    parameters.mysqlDatabaseVersion
					deletionProtection: false
					settings: {
						availabilityType: parameters.mysqlAvailabilityType
						backupConfiguration: {
							binaryLogEnabled: true
							enabled:          true
						}
						edition: "ENTERPRISE"
						ipConfiguration: {
							ipv4Enabled: true
							authorizedNetworks: [
								{
									value: "0.0.0.0/0"
									name:  "All"
								},
							]
							sslMode: "ENCRYPTED_ONLY"
						}
						tier: "db-custom-\(parameters.mysqlCpuCount)-\(parameters.mysqlMemorySizeMb)"
					}
				}
			}

			"\(_mysqlRootUser)": gcp.#GcpCloudSqlUser & {
				options: _gcpProvider
				properties: {
					instance: "${\(_mysqlInstance).name}"
					name:     "root"
					host:     "%"
					password: "${\(_mysqlRootPassword).result}"
				}
			}

			"\(_mysqlRootPassword)": random.#RandomPassword & {
				properties: {
					length:     16
					minLower:   1
					minNumeric: 1
					minSpecial: 1
					minUpper:   1
				}
			}

			"\(_mysqlRootPasswordSecret)": gcp.#GcpSecretManagerSecret & {
				options: _gcpProvider
				properties: {
					replication: {
						auto: {}
					}
					secretId: "qvs-\(parameters.appName)-mysql-root-password"
				}
			}

			"\(_mysqlRootPasswordSecretVersion)": gcp.#GcpSecretManagerSecretVersion & {
				options: _gcpProvider
				properties: {
					secret: "${\(_mysqlRootPasswordSecret).id}"
					secretData: {
						"fn::secret": "${\(_mysqlRootPassword).result}"
					}
				}
			}
		}
	}

	pipelines: _
}
