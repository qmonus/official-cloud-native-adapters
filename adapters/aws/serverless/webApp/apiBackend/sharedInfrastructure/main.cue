package sharedInfrastructure

import (
	"strconv"
	"strings"

	"qmonus.net/adapter/official/types:aws"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                               string
		awsRegion:                             string
		subnet1AvailabilityZone:               string
		subnet2AvailabilityZone:               string & !=parameters.subnet1AvailabilityZone
		rdsEngineVersion:                      strings.HasPrefix("8.0.mysql_aurora")
		rdsBackupRetentionPeriod:              string | *"1"
		rdsPerformanceInsightsRetentionPeriod: string | *"7"
		rdsCloudWatchLogsExportsType:          *"standard" | "all"
		rdsApplyImmediately:                   "true" | *"false"
		rdsBackupWindow:                       string | *"18:00-18:30"
		rdsMaintenanceWindow:                  string | *"tue:19:00-tue:19:30"
		auroraServerlessv2MaxAcu:              string | *"16"
		auroraServerlessv2MinAcu:              string | *"2"
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
					gcp:        false
					aws:        true
					azure:      false
				}
				importStackName: ""
			}
		},
	]

	let _amazonWebServicesProvider = "awsProvider"
	let _vpc = "vpc"
	let _subnet1 = "subnet1"
	let _subnet2 = "subnet2"
	let _internetGateway = "internetGateway"
	let _routeTable = "routeTable"
	let _routeTableAssociationWithSubnet1 = "routeTableAssociationWithSubnet1"
	let _routeTableAssociationWithSubnet2 = "routeTableAssociationWithSubnet2"
	let _securityGroup = "securityGroup"
	let _securityGroupIngressRuleAllowMySQL = "securityGroupIngressRuleAllowMySQL"
	let _securityGroupEgressRuleAllowAll = "securityGroupEgressRuleAllowAll"
	let _dbSubnetGroup = "dbSubnetGroup"
	let _dbClusterParameterGroup = "dbClusterParameterGroup"
	let _dbMasterPassword = "dbMasterPassword"
	let _dbMasterPasswordSecret = "dbMasterPasswordSecret"
	let _dbMasterPasswordSecretVersion = "dbMasterPasswordSecretVersion"
	let _rdsEnhancedMonitoringRole = "rdsEnhancedMonitoringRole"
	let _dbCluster = "dbCluster"
	let _dbClusterInstance1 = "dbClusterInstance1"
	let _dbClusterInstance2 = "dbClusterInstance2"
	let _ecrRepository = "ecrRepository"

	resources: app: {
		_awsProvider: provider: "${\(_amazonWebServicesProvider)}"

		"\(_amazonWebServicesProvider)": aws.#AwsProvider & {
			properties: {
				region: parameters.awsRegion
			}
		}

		"\(_vpc)": aws.#AwsVpc & {
			options: _awsProvider
			properties: {
				cidrBlock:          "10.0.0.0/16"
				enableDnsHostnames: true
				enableDnsSupport:   true
				tags: {
					Name: "qvs-\(parameters.appName)-vpc"
				}
			}
		}

		"\(_subnet1)": aws.#AwsSubnet & {
			options: _awsProvider
			properties: {
				vpcId:            "${\(_vpc).id}"
				cidrBlock:        "10.0.4.0/22"
				availabilityZone: parameters.subnet1AvailabilityZone
				tags: {
					Name: "qvs-\(parameters.appName)-subnet-1"
				}
			}
		}

		"\(_subnet2)": aws.#AwsSubnet & {
			options: _awsProvider
			properties: {
				vpcId:            "${\(_vpc).id}"
				cidrBlock:        "10.0.8.0/22"
				availabilityZone: parameters.subnet2AvailabilityZone
				tags: {
					Name: "qvs-\(parameters.appName)-subnet-2"
				}
			}
		}

		"\(_internetGateway)": aws.#AwsInternetGateway & {
			options: _awsProvider
			properties: {
				vpcId: "${\(_vpc).id}"
				tags: {
					Name: "qvs-\(parameters.appName)-igw"
				}
			}
		}

		"\(_routeTable)": aws.#AwsRouteTable & {
			options: _awsProvider
			properties: {
				vpcId: "${\(_vpc).id}"
				routes: [
					{
						cidrBlock: "${\(_vpc).cidrBlock}"
						gatewayId: "local"
					},
					{
						cidrBlock: "0.0.0.0/0"
						gatewayId: "${\(_internetGateway).id}"
					},
				]
				tags: {
					Name: "qvs-\(parameters.appName)-rtb"
				}
			}
		}

		"\(_routeTableAssociationWithSubnet1)": aws.#AwsRouteTableAssociation & {
			options: _awsProvider
			properties: {
				subnetId:     "${\(_subnet1).id}"
				routeTableId: "${\(_routeTable).id}"
			}
		}

		"\(_routeTableAssociationWithSubnet2)": aws.#AwsRouteTableAssociation & {
			options: _awsProvider
			properties: {
				subnetId:     "${\(_subnet2).id}"
				routeTableId: "${\(_routeTable).id}"
			}
		}

		"\(_securityGroup)": aws.#AwsSecurityGroup & {
			options: _awsProvider
			properties: {
				name:        "qvs-\(parameters.appName)-sg-allow-mysql"
				description: "Allow MySQL traffic"
				vpcId:       "${\(_vpc).id}"
				tags: {
					Name: "qvs-\(parameters.appName)-sg-allow-mysql"
				}
			}
		}

		"\(_securityGroupIngressRuleAllowMySQL)": aws.#AwsSecurityGroupIngressRule & {
			options: _awsProvider
			properties: {
				securityGroupId: "${\(_securityGroup).id}"
				cidrIpv4:        "0.0.0.0/0"
				ipProtocol:      "tcp"
				fromPort:        3306
				toPort:          3306
			}
		}

		"\(_securityGroupEgressRuleAllowAll)": aws.#AwsSecurityGroupEgressRule & {
			options: _awsProvider
			properties: {
				securityGroupId: "${\(_securityGroup).id}"
				cidrIpv4:        "0.0.0.0/0"
				ipProtocol:      "-1"
			}
		}

		"\(_dbSubnetGroup)": aws.#AwsRdsSubnetGroup & {
			options: _awsProvider
			properties: {
				name:        "qvs-\(parameters.appName)-db-subnet-group"
				description: "Managed by Qmonus Value Stream"
				subnetIds: [
					"${\(_subnet1).id}",
					"${\(_subnet2).id}",
				]
				tags: {
					Name: "qvs-\(parameters.appName)-db-subnet-group"
				}
			}
		}

		"\(_dbClusterParameterGroup)": aws.#AwsRdsClusterParameterGroup & {
			options: _awsProvider
			properties: {
				name:        "qvs-\(parameters.appName)-db-cluster-parameter-group"
				description: "Managed by Qmonus Value Stream"
				family:      "aurora-mysql8.0"
				"parameters": [
					{
						name:  "server_audit_logging"
						value: 1
					},
					{
						name:  "server_audit_events"
						value: "CONNECT,QUERY,TABLE"
					},
					{
						name:  "slow_query_log"
						value: 1
					},
					if parameters.rdsCloudWatchLogsExportsType == "all" {
						{
							name:  "general_log"
							value: 1
						}
					},
				]
				tags: {
					Name: "qvs-\(parameters.appName)-db-cluster-parameter-group"
				}
			}
		}

		"\(_dbMasterPassword)": random.#RandomPassword & {
			properties: {
				length:     16
				minLower:   1
				minNumeric: 1
				minSpecial: 1
				minUpper:   1
				// take into consideration limitation for Amazon RDS Master Password
				overrideSpecial: "!#$%&*()-_=+[]{}<>:?"
			}
		}

		"\(_dbMasterPasswordSecret)": aws.#AwsSecretsManagerSecret & {
			options: _awsProvider
			properties: {
				namePrefix:           "qvs-\(parameters.appName)-db-master-password-"
				recoveryWindowInDays: 7
			}
		}

		"\(_dbMasterPasswordSecretVersion)": aws.#AwsSecretsManagerSecretVersion & {
			options: _awsProvider
			properties: {
				secretId:     "${\(_dbMasterPasswordSecret).id}"
				secretString: "${\(_dbMasterPassword).result}"
			}
		}

		"\(_rdsEnhancedMonitoringRole)": aws.#AwsIamRole & {
			options: _awsProvider
			properties: {
				name: "qvs-\(parameters.appName)-rds-monitoring-role"
				assumeRolePolicy: {
					"fn::invoke": {
						function: "aws:iam:getPolicyDocument"
						options:  _awsProvider
						arguments: {
							statements: [
								{
									actions: [
										"sts:AssumeRole",
									]
									effect: "Allow"
									principals: [
										{
											type: "Service"
											identifiers: [
												"monitoring.rds.amazonaws.com",
											]
										},
									]
								},
							]
						}
						return: "json"
					}
				}
				managedPolicyArns: [
					"arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole",
				]
				tags: {
					Name: "qvs-\(parameters.appName)-rds-monitoring-role"
				}
			}
		}

		"\(_dbCluster)": aws.#AwsRdsCluster & {
			options: _awsProvider
			properties: {
				clusterIdentifierPrefix:     "qvs-db-cluster-"
				engine:                      "aurora-mysql"
				engineMode:                  "provisioned"
				engineVersion:               parameters.rdsEngineVersion
				applyImmediately:            strconv.ParseBool(parameters.rdsApplyImmediately)
				backupRetentionPeriod:       strconv.Atoi(parameters.rdsBackupRetentionPeriod)
				copyTagsToSnapshot:          true
				dbClusterParameterGroupName: "${\(_dbClusterParameterGroup).name}"
				dbSubnetGroupName:           "${\(_dbSubnetGroup).name}"
				deleteAutomatedBackups:      false
				deletionProtection:          false
				enabledCloudwatchLogsExports: [
					"audit",
					"error",
					"slowquery",
					if parameters.rdsCloudWatchLogsExportsType == "all" {
						"general"
					},
				]
				iamDatabaseAuthenticationEnabled: false
				masterUsername:                   "root"
				masterPassword:                   "${\(_dbMasterPassword).result}"
				port:                             3306
				preferredBackupWindow:            parameters.rdsBackupWindow
				preferredMaintenanceWindow:       parameters.rdsMaintenanceWindow
				serverlessv2ScalingConfiguration: {
					maxCapacity: strconv.ParseFloat(parameters.auroraServerlessv2MaxAcu, 64)
					minCapacity: strconv.ParseFloat(parameters.auroraServerlessv2MinAcu, 64)
				}
				skipFinalSnapshot: true
				storageEncrypted:  true
				vpcSecurityGroupIds: [
					"${\(_securityGroup).id}",
				]
			}
		}

		"\(_dbClusterInstance1)": aws.#AwsRdsClusterInstance & {
			options: _awsProvider
			properties: {
				identifierPrefix:                   "qvs-db-instance-"
				clusterIdentifier:                  "${\(_dbCluster).id}"
				engine:                             "${\(_dbCluster).engine}"
				instanceClass:                      "db.serverless"
				autoMinorVersionUpgrade:            false
				monitoringInterval:                 60
				monitoringRoleArn:                  "${\(_rdsEnhancedMonitoringRole).arn}"
				performanceInsightsEnabled:         true
				performanceInsightsRetentionPeriod: strconv.Atoi(parameters.rdsPerformanceInsightsRetentionPeriod)
				preferredMaintenanceWindow:         parameters.rdsMaintenanceWindow
				publiclyAccessible:                 true
			}
		}

		"\(_dbClusterInstance2)": aws.#AwsRdsClusterInstance & {
			options: _awsProvider
			properties: {
				identifierPrefix:                   "qvs-db-instance-"
				clusterIdentifier:                  "${\(_dbCluster).id}"
				engine:                             "${\(_dbCluster).engine}"
				instanceClass:                      "db.serverless"
				autoMinorVersionUpgrade:            false
				monitoringInterval:                 60
				monitoringRoleArn:                  "${\(_rdsEnhancedMonitoringRole).arn}"
				performanceInsightsEnabled:         true
				performanceInsightsRetentionPeriod: strconv.Atoi(parameters.rdsPerformanceInsightsRetentionPeriod)
				preferredMaintenanceWindow:         parameters.rdsMaintenanceWindow
				publiclyAccessible:                 true
			}
		}

		"\(_ecrRepository)": aws.#AwsEcrRepository & {
			options: _awsProvider
			properties: {
				name:        "qvs-\(parameters.appName)-repository"
				forceDelete: true
				tags: {
					Name: "qvs-\(parameters.appName)-repository"
				}
			}
		}
	}

	pipelines: _
}
