package fullStack

import (
	"strings"
	"strconv"

	"qmonus.net/adapter/official/adapters:utils"
	"qmonus.net/adapter/official/types:base"
	"qmonus.net/adapter/official/types:gcp"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/pipeline/build:buildkitGcp"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                  string
		gcpProjectId:             string
		region:                   string | *"asia-northeast1"
		imageUrl:                 string
		port:                     string
		cloudrunMaxInstanceCount: string | *"100"
		environmentVariables: [string]: string
		secrets: [string]:              base.#Secret
		mysqlDatabaseName:        string
		mysqlUserName:            string
		mysqlCpuCount:            string | *"2"
		mysqlMemorySizeMb:        string | *"4096"
		mysqlDatabaseVersion:     strings.HasPrefix("MYSQL_") | *"MYSQL_8_0"
		mysqlAvailabilityType:    *"ZONAL" | "REGIONAL"
		privateServiceAccessCidr: string | *"172.20.16.0/22"
		cloudrunDirectEgressCidr: string | *"172.20.20.0/22"
		dnsARecordSubdomain:      strings.HasSuffix(".")
		dnsZoneProjectId:         string | *parameters.gcpProjectId
		dnsZoneName:              string
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
					kubernetes: false
					gcp:        true
					aws:        false
					azure:      false
				}
				importStackName: ""
			}
		},
	]

	resources: app: {
		// Provider
		gcpProvider: gcp.#GcpProvider & {
			properties: {
				project: parameters.gcpProjectId
			}
		}

		// Cloud Run
		serviceaccount: gcp.#GcpServiceAccount & {
			options: provider: "${gcpProvider}"
			properties: {
				accountId:   parameters.appName
				displayName: parameters.appName
			}
		}
		secretAccessor_DB_PASSWORD: gcp.#GcpSecretIamMember & {
			options: provider: "${gcpProvider}"
			properties: {
				project:  parameters.gcpProjectId
				secretId: "${sqlPasswordSecret.id}"
				role:     "roles/secretmanager.secretAccessor"
				member:   "serviceAccount:${serviceaccount.email}"
			}
		}
		for secretKey, secret in parameters.secrets {
			"secretAccessor_\(secretKey)": gcp.#GcpSecretIamMember & {
				options: provider: "${gcpProvider}"
				properties: {
					project:  parameters.gcpProjectId
					secretId: secret.key
					role:     "roles/secretmanager.secretAccessor"
					member:   "serviceAccount:${serviceaccount.email}"
				}
			}
		}
		noauth: gcp.#GcpCloudrunServiceIamMember & {
			options: provider: "${gcpProvider}"
			properties: {
				name:     "${cloudrun.name}"
				location: "${cloudrun.location}"
				role:     "roles/run.invoker"
				member:   "allUsers"
			}
		}
		cloudrun: gcp.#GcpCloudrunService & {
			options: provider: "${gcpProvider}"
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 50}}.out
				name:     "qvs-\(_appName)-cloudrun"
				location: parameters.region
				ingress:  "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
				template: {
					containers: [{
						image: parameters.imageUrl
						ports: [{
							containerPort: strconv.Atoi(parameters.port)
						}]
						envs: [
							{
								name:  "DB_HOST"
								value: "${sqlInstance.privateIpAddress}"
							},
							{
								name:  "DB_NAME"
								value: "${sqlDatabase.name}"
							},
							{
								name:  "DB_USER"
								value: "${sqlUser.name}"
							},
							{
								name:  "DB_PASSWORD"
								value: "${sqlPassword.result}"
							},
							{
								name:  "SERVICE_URL"
								value: strings.TrimSuffix(parameters.dnsARecordSubdomain, ".")
							},
							for k, v in parameters.environmentVariables {
								{
									name:  k
									value: v
								}
							},
							for k, v in parameters.secrets {
								{
									name: k
									valueSource: {
										secretKeyRef: {
											secret:  v.key
											version: v.version
										}
									}
								}
							},
						]
					}]
					scaling: maxInstanceCount: strconv.Atoi(parameters.cloudrunMaxInstanceCount)
					vpcAccess: {
						networkInterfaces: [{
							network:    "${vpcNetwork.id}"
							subnetwork: "${directEgressSubnet.id}"
						}]
						egress: "PRIVATE_RANGES_ONLY"
					}
					serviceAccount: "${serviceaccount.email}"
				}
			}
		}

		// SQL
		sqlAccessPermission: gcp.#GcpIamMember & {
			options: provider: "${gcpProvider}"
			properties: {
				project: parameters.gcpProjectId
				role:    "roles/cloudsql.client"
				member:  "serviceAccount:${serviceaccount.email}"
				condition: {
					title:       "Allow access to specific CloudSQL instance only"
					description: "Grants CloudSQL client access only to the specified instance"
					expression: #"""
						resource.name.endsWith('instances/${sqlInstance}') &&
						resource.type == 'sqladmin.googleapis.com/Instance'
						"""#
				}
			}
		}
		sqlInstance: gcp.#GcpCloudSqlInstance & {
			options: provider: "${gcpProvider}"
			options: dependsOn: ["${privateVpcConnection}"]

			properties: {
				// The total length of project-ID:instance-ID must be 98 characters or less.
				// See: https://cloud.google.com/sql/docs/mysql/instance-settings#instance-id-2ndgen
				let _totalLength = 98
				let _projectIdLength = len(parameters.gcpProjectId)
				let _colonLength = 1

				// the length of "qvs-" and "-mysql"
				let _otherLength = 6
				let _appName = {utils.#trim & {str: parameters.appName, limit: _totalLength - _projectIdLength - _colonLength - _otherLength}}.out
				name:               "qvs-\(_appName)-mysql"
				databaseVersion:    parameters.mysqlDatabaseVersion
				deletionProtection: false
				region:             parameters.region
				settings: {
					availabilityType: parameters.mysqlAvailabilityType
					edition:          "ENTERPRISE"
					ipConfiguration: {
						ipv4Enabled:    false
						privateNetwork: "${vpcNetwork.id}"
					}
					tier: "db-custom-\(parameters.mysqlCpuCount)-\(parameters.mysqlMemorySizeMb)"
				}
			}
		}
		sqlDatabase: gcp.#GcpCloudSqlDatabase & {
			options: provider: "${gcpProvider}"
			properties: {
				name:     parameters.mysqlDatabaseName
				instance: "${sqlInstance.name}"
				charset:  "utf8mb4"
			}
		}
		sqlUser: gcp.#GcpCloudSqlUser & {
			options: provider: "${gcpProvider}"
			properties: {
				name:     parameters.mysqlUserName
				instance: "${sqlInstance.name}"
				host:     "%"
				password: "${sqlPassword.result}"
			}
		}
		sqlPassword: random.#RandomPassword & {
			properties: {
				length:     16
				minLower:   1
				minUpper:   1
				minNumeric: 1
				special:    false
			}
		}
		sqlPasswordSecret: gcp.#GcpSecretManagerSecret & {
			options: provider: "${gcpProvider}"
			properties: {
				secretId: "qvs-\(parameters.appName)-mysql-user-password"
				replication: auto: {}
			}
		}
		sqlPasswordSecretVersion: gcp.#GcpSecretManagerSecretVersion & {
			options: provider: "${gcpProvider}"
			properties: {
				secret:     "${sqlPasswordSecret.id}"
				secretData: "${sqlPassword.result}"
				enabled:    true
			}
		}

		// DNS
		dnsARecord: gcp.#GcpCloudDnsRecordSet & {
			options: provider: "${gcpProvider}"
			properties: {
				name:        parameters.dnsARecordSubdomain
				managedZone: parameters.dnsZoneName
				project:     parameters.dnsZoneProjectId
				type:        "A"
				ttl:         3600
				rrdatas: ["${globalIp.address}"]
			}
		}

		// LB
		globalIp: gcp.#GcpGlobalIpAddress & {
			options: provider: "${gcpProvider}"
			properties: name:  parameters.appName
		}

		sslCert: gcp.#GcpManagedSslCertificate & {
			options: provider: "${gcpProvider}"
			properties: {
				name: parameters.appName
				managed: domains: [strings.TrimSuffix(parameters.dnsARecordSubdomain, ".")]
			}
		}
		backendService: gcp.#GcpBackendService & {
			options: provider: "${gcpProvider}"
			properties: {
				name:       parameters.appName
				protocol:   "HTTP"
				timeoutSec: 30
				backends: [{
					group: "${lbNeg.id}"
				}]
			}
		}
		urlMap: gcp.#GcpUrlMap & {
			options: provider: "${gcpProvider}"
			properties: {
				name:           parameters.appName
				defaultService: "${backendService.id}"
			}
		}
		lb: gcp.#GcpTargetHttpsProxy & {
			options: provider: "${gcpProvider}"
			properties: {
				name:   parameters.appName
				urlMap: "${urlMap.id}"
				sslCertificates: ["${sslCert.id}"]
			}
		}
		forwardingRule: gcp.#GcpGlobalForwardingRule & {
			options: provider: "${gcpProvider}"
			properties: {
				name:      parameters.appName
				target:    "${lb.id}"
				portRange: "443"
				ipAddress: "${globalIp.address}"
			}
		}
		lbNeg: gcp.#GcpRegionNetworkEndpointGroup & {
			options: provider: "${gcpProvider}"
			properties: {
				name:                parameters.appName
				networkEndpointType: "SERVERLESS"
				region:              parameters.region
				cloudRun: service: "${cloudrun.name}"
			}
		}

		// VPC for SQL
		vpcNetwork: gcp.#GcpVpcNetwork & {
			options: provider: "${gcpProvider}"
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 52}}.out
				name:                  "qvs-\(_appName)-vpc-nw"
				autoCreateSubnetworks: false
			}
		}
		directEgressSubnet: gcp.#GcpSubnet & {
			options: provider: "${gcpProvider}"
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 52}}.out
				name:        "qvs-\(_appName)-subnet"
				ipCidrRange: parameters.cloudrunDirectEgressCidr
				network:     "${vpcNetwork.id}"
				region:      parameters.region
			}
		}
		privateIpAddress: gcp.#GcpGlobalIpAddress & {
			options: provider: "${gcpProvider}"
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 48}}.out
				name:         "qvs-\(_appName)-private-ip"
				purpose:      "VPC_PEERING"
				addressType:  "INTERNAL"
				address:      strings.Split(parameters.privateServiceAccessCidr, "/")[0]
				prefixLength: strconv.Atoi(strings.Split(parameters.privateServiceAccessCidr, "/")[1])
				network:      "${vpcNetwork.id}"
			}
		}
		privateVpcConnection: gcp.#GcpServiceNetworkingConnection & {
			options: provider: "${gcpProvider}"
			properties: {
				network: "${vpcNetwork.id}"
				service: "servicenetworking.googleapis.com"
				reservedPeeringRanges: ["${privateIpAddress.name}"]
			}
		}
	}

	pipelines: {}
}
