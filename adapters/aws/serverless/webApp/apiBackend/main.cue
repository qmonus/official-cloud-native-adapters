package apiBackend

import (
	"strconv"
	"list"

	"qmonus.net/adapter/official/adapters:utils"
	"qmonus.net/adapter/official/types:aws"
	"qmonus.net/adapter/official/types:mysql"
	"qmonus.net/adapter/official/types:random"
	"qmonus.net/adapter/official/pipeline/build:buildkitAws"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                      string
		awsAccountId:                 string
		awsRegion:                    string
		dnsZoneId:                    string
		appRunnerServiceCpu:          string | *"1024"
		appRunnerServiceMemory:       string | *"2048"
		appRunnerServicePort:         string
		appRunnerServiceCustomDomain: string
		appRunnerServiceImageUri:     string
		wafAllowedSourceIps: [...string]
		wafLogGroupRetentionInDays:               string | *"365"
		rdsEndpoint:                              string
		rdsEndpointEnvironmentVariableName:       string | *"DB_HOST"
		rdsMasterPasswordSecretArn:               string
		mysqlDatabaseName:                        string
		mysqlDatabaseNameEnvironmentVariableName: string | *"DB_NAME"
		mysqlUserName:                            string
		mysqlUserNameEnvironmentVariableName:     string | *"DB_USER"
		mysqlUserPasswordEnvironmentVariableName: string | *"DB_PASS"
		secretsArn: [string]:           string
		environmentVariables: [string]: string
	}

	pipelineParameters: {
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
		{
			pattern: buildkitAws.DesignPattern
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
					gcp:        false
					aws:        true
					azure:      false
				}
				importStackName: ""
			}
		},
	]

	let _amazonWebServicesProvider = "awsProvider"
	let _resourceSuffix = "resourceSuffix"
	let _appRunnerService = "appRunnerService"
	let _appRunnerServiceEcrAccessRole = "appRunnerServiceEcrAccessRole"
	let _appRunnerServiceInstanceRole = "appRunnerServiceInstanceRole"
	let _appRunnerServiceInstanceRolePolicy = "appRunnerServiceInstanceRolePolicy"
	let _appRunnerCustomDomainAssociation = "appRunnerCustomDomainAssociation"
	let _aliasRecord = "aliasRecord"
	let _cnameRecord1 = "cnameRecord1"
	let _cnameRecord2 = "cnameRecord2"
	let _ipSet = "ipSet"
	let _webAcl = "webAcl"
	let _webAclAssociation = "webAclAssociation"
	let _webAclLoggingConfiguration = "webAclLoggingConfiguration"
	let _webAclLogGroup = "webAclLogGroup"
	let _logResourcePolicyForWafLogging = "logResourcePolicyForWafLogging"
	let _mysqlProvider = "mysqlProvider"
	let _database = "database"
	let _user = "user"
	let _grant = "grant"
	let _userPassword = "userPassword"
	let _userPasswordSecret = "userPasswordSecret"
	let _userPasswordSecretVersion = "userPasswordSecretVersion"

	resources: app: {
		_awsProvider: provider: "${\(_amazonWebServicesProvider)}"

		"\(_amazonWebServicesProvider)": aws.#AwsProvider & {
			properties: {
				region: parameters.awsRegion
			}
		}

		"\(_resourceSuffix)": random.#RandomString & {
			properties: {
				length:  3
				special: false
				upper:   false
			}
		}

		// check that "environmentVariables" does not contain
		// a reserved environment variable for App Runner service
		#environmentVariablesSchema: {
			name:  string & !="PORT"
			value: string
		}
		let _environmentVariablesList = [
			for n, v in parameters.environmentVariables {
				#environmentVariablesSchema & {
					name:  n
					value: v
				}
			},
		]
		let _environmentVariables = {
			for e in _environmentVariablesList {
				"\(e.name)": e.value
			}
		}

		"\(_appRunnerService)": aws.#AwsAppRunnerService & {
			options: _awsProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 32}}.out
				let _name = "qvs-\(_appName)-${\(_resourceSuffix).result}"
				serviceName: _name
				sourceConfiguration: {
					imageRepository: {
						imageConfiguration: {
							port: strconv.Atoi(parameters.appRunnerServicePort)
							runtimeEnvironmentVariables: {
								"\(parameters.rdsEndpointEnvironmentVariableName)":       parameters.rdsEndpoint
								"\(parameters.mysqlDatabaseNameEnvironmentVariableName)": parameters.mysqlDatabaseName
								"\(parameters.mysqlUserNameEnvironmentVariableName)":     parameters.mysqlUserName
								_environmentVariables
							}
							runtimeEnvironmentSecrets: {
								"\(parameters.mysqlUserPasswordEnvironmentVariableName)": "${\(_userPasswordSecret).arn}"
								parameters.secretsArn
							}
						}
						imageIdentifier:     parameters.appRunnerServiceImageUri
						imageRepositoryType: "ECR"
					}
					authenticationConfiguration: {
						accessRoleArn: "${\(_appRunnerServiceEcrAccessRole).arn}"
					}
					autoDeploymentsEnabled: false
				}
				instanceConfiguration: {
					cpu:             parameters.appRunnerServiceCpu
					memory:          parameters.appRunnerServiceMemory
					instanceRoleArn: "${\(_appRunnerServiceInstanceRole).arn}"
				}
				tags: {
					Name: _name
				}
			}
		}

		"\(_appRunnerServiceEcrAccessRole)": aws.#AwsIamRole & {
			options: _awsProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 29}}.out
				let _name = "qvs-\(_appName)-app-runner-ecr-access-role-${\(_resourceSuffix).result}"
				name: _name
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
												"build.apprunner.amazonaws.com",
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
					"arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess",
				]
				tags: {
					Name: _name
				}
			}
		}

		"\(_appRunnerServiceInstanceRole)": aws.#AwsIamRole & {
			options: _awsProvider
			properties: {
				let _appName = {utils.#trim & {str: parameters.appName, limit: 31}}.out
				let _name = "qvs-\(_appName)-app-runner-instance-role-${\(_resourceSuffix).result}"
				name: _name
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
												"tasks.apprunner.amazonaws.com",
											]
										},
									]
								},
							]
						}
						return: "json"
					}
				}
				tags: {
					Name: _name
				}
			}
		}

		let _secretsArnValueList = [
			for n, v in parameters.secretsArn {
				v
			},
		]

		// sort to make results deterministic
		let _secretsArnValueListSorted = list.SortStrings(_secretsArnValueList)

		"\(_appRunnerServiceInstanceRolePolicy)": aws.#AwsIamRolePolicy & {
			options: _awsProvider
			properties: {
				name: "qvs-\(parameters.appName)-app-runner-instance-role-policy-${\(_resourceSuffix).result}"
				role: "${\(_appRunnerServiceInstanceRole).id}"
				policy: {
					"fn::invoke": {
						function: "aws:iam:getPolicyDocument"
						options:  _awsProvider
						arguments: {
							statements: [
								{
									actions: [
										"secretsmanager:GetSecretValue",
										"kms:Decrypt*",
									]
									effect: "Allow"
									resources: [
										"${\(_userPasswordSecret).arn}",
										for e in _secretsArnValueListSorted {
											e
										},
									]
								},
							]
						}
						return: "json"
					}
				}
			}
		}

		"\(_appRunnerCustomDomainAssociation)": aws.#AwsAppRunnerCustomDomainAssociation & {
			options: _awsProvider
			properties: {
				domainName:         parameters.appRunnerServiceCustomDomain
				serviceArn:         "${\(_appRunnerService).arn}"
				enableWwwSubdomain: false
			}
		}

		"\(_aliasRecord)": aws.#AwsRoute53Record & {
			options: _awsProvider
			properties: {
				zoneId: parameters.dnsZoneId
				name:   "${\(_appRunnerCustomDomainAssociation).domainName}"
				type:   "A"
				aliases: [
					{
						name: "${\(_appRunnerCustomDomainAssociation).dnsTarget}"
						zoneId: {
							"fn::invoke": {
								function: "aws:apprunner/getHostedZoneId:getHostedZoneId"
								options:  _awsProvider
								arguments: {
									region: parameters.awsRegion
								}
								return: "id"
							}
						}
						evaluateTargetHealth: true
					},
				]
			}
		}

		"\(_cnameRecord1)": aws.#AwsRoute53Record & {
			options: _awsProvider
			properties: {
				zoneId: parameters.dnsZoneId
				// this resource assumes that length of "certificateValidationRecords" is 2.
				// if the length becomes more or less than 2, this resource causes unexpected result.
				name: "${\(_appRunnerCustomDomainAssociation).certificateValidationRecords[0].name}"
				type: "CNAME"
				ttl:  30
				records: [
					"${\(_appRunnerCustomDomainAssociation).certificateValidationRecords[0].value}",
				]
			}
		}

		"\(_cnameRecord2)": aws.#AwsRoute53Record & {
			options: _awsProvider
			properties: {
				zoneId: parameters.dnsZoneId
				// this resource assumes that length of "certificateValidationRecords" is 2.
				// if the length becomes more or less than 2, this resource causes unexpected result.
				name: "${\(_appRunnerCustomDomainAssociation).certificateValidationRecords[1].name}"
				type: "CNAME"
				ttl:  30
				records: [
					"${\(_appRunnerCustomDomainAssociation).certificateValidationRecords[1].value}",
				]
			}
		}

		let _numberOfAllowedSourceIps = len(parameters.wafAllowedSourceIps)
		if _numberOfAllowedSourceIps > 0 {
			"\(_ipSet)": aws.#AwsWafIpSet & {
				options: _awsProvider
				properties: {
					let _name = "qvs-\(parameters.appName)-ip-set-${\(_resourceSuffix).result}"
					name:             _name
					scope:            "REGIONAL"
					ipAddressVersion: "IPV4"
					addresses:        parameters.wafAllowedSourceIps
					tags: {
						Name: _name
					}
				}
			}
		}

		"\(_webAcl)": aws.#AwsWafWebAcl & {
			options: _awsProvider
			properties: {
				let _name = "qvs-\(parameters.appName)-web-acl-${\(_resourceSuffix).result}"
				name:  _name
				scope: "REGIONAL"
				visibilityConfig: {
					sampledRequestsEnabled:   true
					cloudwatchMetricsEnabled: true
					metricName:               _name
				}
				if _numberOfAllowedSourceIps == 0 {
					defaultAction: {
						allow: {}
					}
				}
				if _numberOfAllowedSourceIps > 0 {
					defaultAction: {
						block: {}
					}
					rules: [
						{
							let _ruleName = "qvs-\(parameters.appName)-whitelist-${\(_resourceSuffix).result}"
							name:     _ruleName
							priority: 0
							statement: {
								ipSetReferenceStatement: {
									arn: "${\(_ipSet).arn}"
								}
							}
							action: {
								allow: {}
							}
							visibilityConfig: {
								sampledRequestsEnabled:   true
								cloudwatchMetricsEnabled: true
								metricName:               _ruleName
							}
						},
					]
				}
				tags: {
					Name: _name
				}
			}
		}

		"\(_webAclAssociation)": aws.#AwsWafWebAclAssociation & {
			options: _awsProvider
			properties: {
				resourceArn: "${\(_appRunnerService).arn}"
				webAclArn:   "${\(_webAcl).arn}"
			}
		}

		"\(_webAclLoggingConfiguration)": aws.#AwsWafWebAclLoggingConfiguration & {
			options: {
				_awsProvider
				dependsOn: [
					"${\(_webAclAssociation)}",
					"${\(_logResourcePolicyForWafLogging)}",
				]
			}
			properties: {
				logDestinationConfigs: [
					"${\(_webAclLogGroup).arn}",
				]
				resourceArn: "${\(_webAcl).arn}"
			}
		}

		"\(_webAclLogGroup)": aws.#AwsCloudwatchLogGroup & {
			options: _awsProvider
			properties: {
				namePrefix:      "aws-waf-logs-qvs-\(parameters.appName)-${\(_resourceSuffix).result}-"
				logGroupClass:   "STANDARD"
				retentionInDays: strconv.Atoi(parameters.wafLogGroupRetentionInDays)
				skipDestroy:     true
			}
		}

		"\(_logResourcePolicyForWafLogging)": aws.#AwsCloudwatchLogResourcePolicy & {
			options: _awsProvider
			properties: {
				policyDocument: {
					"fn::invoke": {
						function: "aws:iam:getPolicyDocument"
						options:  _awsProvider
						arguments: {
							statements: [
								{
									actions: [
										"logs:CreateLogStream",
										"logs:PutLogEvents",
									]
									effect: "Allow"
									resources: [
										"${\(_webAclLogGroup).arn}:log-stream:*",
									]
									principals: [
										{
											type: "Service"
											identifiers: [
												"delivery.logs.amazonaws.com",
											]
										},
									]
									conditions: [
										{
											test:     "StringEquals"
											variable: "aws:SourceAccount"
											values: [
												parameters.awsAccountId,
											]
										},
										{
											test:     "ArnLike"
											variable: "aws:SourceArn"
											values: [
												"arn:aws:logs:\(parameters.awsRegion):\(parameters.awsAccountId):*",
											]
										},
									]
								},
							]
						}
						return: "json"
					}
				}
				policyName: "qvs-\(parameters.appName)-waf-logging-policy-${\(_resourceSuffix).result}"
			}
		}

		"\(_mysqlProvider)": mysql.#MysqlProvider & {
			properties: {
				endpoint: parameters.rdsEndpoint
				username: "root"
				password: {
					"fn::secret": {
						"fn::invoke": {
							function: "aws:secretsmanager:getSecretVersion"
							options:  _awsProvider
							arguments: {
								secretId: parameters.rdsMasterPasswordSecretArn
							}
							return: "secretString"
						}
					}
				}
				tls: "skip-verify"
			}
		}

		"\(_database)": mysql.#MysqlDatabase & {
			options: provider: "${\(_mysqlProvider)}"
			properties: {
				name:                parameters.mysqlDatabaseName
				defaultCharacterSet: "utf8mb4"
				defaultCollation:    "utf8mb4_0900_ai_ci"
			}
		}

		"\(_user)": mysql.#MysqlUser & {
			options: provider: "${\(_mysqlProvider)}"
			properties: {
				user:              parameters.mysqlUserName
				host:              "%"
				plaintextPassword: "${\(_userPassword).result}"
			}
		}

		"\(_grant)": mysql.#MysqlGrant & {
			options: provider: "${\(_mysqlProvider)}"
			properties: {
				database: "${\(_database).name}"
				user:     "${\(_user).user}"
				host:     "%"
				privileges: ["ALL"]
				table: "*"
			}
		}

		"\(_userPassword)": random.#RandomPassword & {
			properties: {
				length:     16
				minLower:   1
				minUpper:   1
				minNumeric: 1
				minSpecial: 1
			}
		}

		"\(_userPasswordSecret)": aws.#AwsSecretsManagerSecret & {
			options: _awsProvider
			properties: {
				namePrefix:           "qvs-\(parameters.appName)-db-user-password-${\(_resourceSuffix).result}-"
				recoveryWindowInDays: 7
			}
		}

		"\(_userPasswordSecretVersion)": aws.#AwsSecretsManagerSecretVersion & {
			options: _awsProvider
			properties: {
				secretId:     "${\(_userPasswordSecret).id}"
				secretString: "${\(_userPassword).result}"
			}
		}
	}

	pipelines: _
}
