package frontend

import (
	"strconv"
	"qmonus.net/adapter/official/types:aws"
	"qmonus.net/adapter/official/types:random"
	publishSite "qmonus.net/adapter/official/pipeline/deploy:awsS3StaticWebSiteHosting"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {

	parameters: {
		appName:           string
		awsRegion:         string
		customDomainName:  string
		dnsZoneId:         string
		bucketName:        string
		indexDocumentName: string
		awsAccountId:      string
		environmentVariables: [string]: string
		enableWaf:                *"true" | "false"
		enableAccessLogging:      *"true" | "false"
		accessLogRetentionInDays: string | *"365"
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
		{
			pattern: publishSite.DesignPattern
			pipelineParams: {
				repositoryKind: pipelineParameters.repositoryKind
				useSshKey:      pipelineParameters.useSshKey
			}
		},
	]

	let _amazonWebServicesProvider = "awsProvider"
	let _amazonWebServicesProviderUS = "awsProviderUS"
	let _awsCertificate = "awsCertificate"
	let _awsCertificateValidationRecord = "awsCertificateValidationRecord"
	let _contentBucket = "contentBucket"
	let _cloudFrontOAC = "cloudFrontOAC"
	let _contentBucketPolicy = "contentBucketPolicy"
	let _cloudFrontDistribution = "cloudFrontDistribution"
	let _dnsRecord = "dnsRecord"
	let _awsWaf = "awsWaf"
	let _awsCloudWatchLogDeliverySource = "awsCloudWatchLogDeliverySource"
	let _awsCloudWatchLogDelivery = "awsCloudWatchLogDelivery"
	let _awsCloudWatchLogGroup = "awsCloudWatchLogGroup"
	let _awsCloudWatchLogDeliveryDestination = "awsCloudWatchLogDeliveryDestination"
	let _enableWaf = strconv.ParseBool(parameters.enableWaf)
	let _enableAccessLogging = strconv.ParseBool(parameters.enableAccessLogging)
	let _accessLogRetentionInDays = strconv.Atoi(parameters.accessLogRetentionInDays)
	let _resourceSuffix = "resourceSuffix"
	let _logResourcePolicyForCloudFrontDistribution = "logResourcePolicyForCloudFrontDistribution"

	resources: app: {

		"\(_resourceSuffix)": random.#RandomString & {
			properties: {
				length:  3
				special: false
				upper:   false
			}
		}

		_awsProvider: provider:   "${\(_amazonWebServicesProvider)}"
		_awsProviderUS: provider: "${\(_amazonWebServicesProviderUS)}"

		"\(_amazonWebServicesProvider)": aws.#AwsProvider & {
			properties: {
				region: parameters.awsRegion
			}
		}

		"\(_amazonWebServicesProviderUS)": aws.#AwsProvider & {
			properties: {
				region: "us-east-1"
			}
		}

		"\(_awsCertificate)": aws.#AwsCertificate & {
			options: _awsProviderUS
			properties: {
				domainName:       parameters.customDomainName
				validationMethod: "DNS"
			}
		}

		"\(_awsCertificateValidationRecord)": aws.#AwsRoute53Record & {
			options: _awsProviderUS
			properties: {
				zoneId: parameters.dnsZoneId
				// this resource assumes that length of "domainValidationOptions" is 1.
				// if the length becomes more or less than 1, this resource causes unexpected result.
				name: "${\(_awsCertificate).domainValidationOptions[0].resourceRecordName}"
				type: "${\(_awsCertificate).domainValidationOptions[0].resourceRecordType}"
				records: [
					"${\(_awsCertificate).domainValidationOptions[0].resourceRecordValue}",
				]
				ttl: 300
			}
		}
		"\(_contentBucket)": aws.#AwsS3BucketV2 & {
			options: _awsProvider
			properties: {
				bucket:       parameters.bucketName
				forceDestroy: true
			}
		}

		"\(_cloudFrontOAC)": aws.#AwsCloudFrontOAC & {
			options: _awsProvider
			properties: {
				name:                          "qvs-\(parameters.appName)-oac-${\(_resourceSuffix).result}"
				description:                   "OAC for secure S3 access"
				originAccessControlOriginType: "s3"
				signingBehavior:               "always"
				signingProtocol:               "sigv4"
			}
		}

		"\(_contentBucketPolicy)": aws.#AwsS3BucketPolicy & {
			options: _awsProvider
			properties: {
				bucket: "${\(_contentBucket).bucket}"
				policy: {
					"fn::invoke": {
						function: "aws:iam:getPolicyDocument"
						options:  _awsProvider
						arguments: {
							version: "2012-10-17"
							statements: [
								{
									actions: [
										"s3:GetObject",
									]
									effect: "Allow"
									resources: [
										"${\(_contentBucket).arn}/*",
									]
									principals: [
										{
											type: "Service"
											identifiers: [
												"cloudfront.amazonaws.com",
											]
										},
									]
									conditions: [
										{
											test:     "StringEquals"
											variable: "aws:SourceArn"
											values: [
												"${\(_cloudFrontDistribution).arn}",
											]
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

		if _enableWaf {
			"\(_awsWaf)": aws.#AwsWafWebAcl & {
				options: _awsProviderUS
				properties: {
					let _name = "qvs-\(parameters.appName)-web-acl-${\(_resourceSuffix).result}"
					name:  _name
					scope: "CLOUDFRONT"
					visibilityConfig: {
						sampledRequestsEnabled:   true
						cloudwatchMetricsEnabled: true
						metricName:               _name
					}
					defaultAction: {
						allow: {}
					}
					rules: [
						{
							name:     "AWS-AWSManagedRulesAmazonIpReputationList"
							priority: 0
							overrideAction: {none: {}}
							statement: {
								managedRuleGroupStatement: {
									name:       "AWSManagedRulesAmazonIpReputationList"
									vendorName: "AWS"
								}
							}
							visibilityConfig: {
								cloudwatchMetricsEnabled: true
								metricName:               "AWS-AWSManagedRulesAmazonIpReputationList"
								sampledRequestsEnabled:   true
							}
						},
						{
							name:     "AWS-AWSManagedRulesCommonRuleSet"
							priority: 1
							overrideAction: {none: {}}
							statement: {
								managedRuleGroupStatement: {
									name:       "AWSManagedRulesCommonRuleSet"
									vendorName: "AWS"
								}
							}
							visibilityConfig: {
								cloudwatchMetricsEnabled: true
								metricName:               "AWS-AWSManagedRulesCommonRuleSet"
								sampledRequestsEnabled:   true
							}
						},
						{
							name:     "AWS-AWSManagedRulesKnownBadInputsRuleSet"
							priority: 2
							overrideAction: {none: {}}
							statement: {
								managedRuleGroupStatement: {
									name:       "AWSManagedRulesKnownBadInputsRuleSet"
									vendorName: "AWS"
								}
							}
							visibilityConfig: {
								cloudwatchMetricsEnabled: true
								metricName:               "AWS-AWSManagedRulesKnownBadInputsRuleSet"
								sampledRequestsEnabled:   true
							}
						},
					]
				}
			}
		}

		if _enableAccessLogging {

			"\(_awsCloudWatchLogGroup)": aws.#AwsCloudWatchLogGroup & {
				options: _awsProviderUS
				properties: {
					name:            "qvs-\(parameters.appName)-cloudfront-log-group-${\(_resourceSuffix).result}"
					retentionInDays: _accessLogRetentionInDays
				}
			}

			"\(_logResourcePolicyForCloudFrontDistribution)": aws.#AwsCloudwatchLogResourcePolicy & {
				options: _awsProviderUS
				properties: {
					policyDocument: {
						"fn::invoke": {
							function: "aws:iam:getPolicyDocument"
							options:  _awsProviderUS
							arguments: {
								statements: [
									{
										actions: [
											"logs:CreateLogStream",
											"logs:PutLogEvents",
										]
										effect: "Allow"
										resources: [
											"${\(_awsCloudWatchLogGroup).arn}:log-stream:*",
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
													"arn:aws:logs:${\(_amazonWebServicesProviderUS).region}:\(parameters.awsAccountId):*",
												]
											},
										]
									},
								]
							}
							return: "json"
						}
					}
					policyName: "qvs-\(parameters.appName)-clf-logging-policy-${\(_resourceSuffix).result}"
				}
			}

			"\(_awsCloudWatchLogDeliverySource)": aws.#AwsCloudWatchLogDeliverySource & {
				options: _awsProviderUS
				properties: {
					name:        "qvs-\(parameters.appName)-cloudfront-log-delivery-source-${\(_resourceSuffix).result}"
					logType:     "ACCESS_LOGS"
					resourceArn: "${\(_cloudFrontDistribution).arn}"
				}
			}

			"\(_awsCloudWatchLogDeliveryDestination)": aws.#AwsCloudWatchLogDeliveryDestination & {
				options: _awsProviderUS
				properties: {
					name: "qvs-\(parameters.appName)-cloudfront-log-destination-${\(_resourceSuffix).result}"
					deliveryDestinationConfiguration: {
						destinationResourceArn: "${\(_awsCloudWatchLogGroup).arn}"
					}
				}
			}

			"\(_awsCloudWatchLogDelivery)": aws.#AwsCloudWatchLogDelivery & {
				options: _awsProviderUS
				properties: {
					deliverySourceName:     "${\(_awsCloudWatchLogDeliverySource).name}"
					deliveryDestinationArn: "${\(_awsCloudWatchLogDeliveryDestination).arn}"
				}
			}
		}

		"\(_cloudFrontDistribution)": aws.#AwsCloudFrontDistribution & {
			options: _awsProvider
			properties: {
				origins: [
					{
						domainName:            "${\(_contentBucket).bucketRegionalDomainName}"
						originId:              "${\(_contentBucket).bucketRegionalDomainName}"
						originAccessControlId: "${\(_cloudFrontOAC).id}"
					},
				]
				enabled:           true
				defaultRootObject: parameters.indexDocumentName
				defaultCacheBehavior: {
					targetOriginId:       "${\(_contentBucket).bucketRegionalDomainName}"
					viewerProtocolPolicy: "redirect-to-https"
					allowedMethods: [
						"GET",
						"HEAD",
					]
					cachedMethods: [
						"GET",
						"HEAD",
					]
					forwardedValues: {
						queryString: false
						cookies: {
							forward: "none"
						}
					}
				}
				if _enableWaf {
					webAclId: "${\(_awsWaf).arn}"
				}
				viewerCertificate: {
					acmCertificateArn: "${\(_awsCertificate).arn}"
					sslSupportMethod:  "sni-only"
				}
				aliases: [
					parameters.customDomainName,
				]
				restrictions: {
					geoRestriction: {
						restrictionType: "none"
					}
				}
			}
		}

		"\(_dnsRecord)": aws.#AwsRoute53Record & {
			options: _awsProvider
			properties: {
				zoneId: parameters.dnsZoneId
				name:   parameters.customDomainName
				type:   "A"
				aliases: [
					{
						name:                 "${\(_cloudFrontDistribution).domainName}"
						zoneId:               "${\(_cloudFrontDistribution).hostedZoneId}"
						evaluateTargetHealth: true
					},
				]
			}
		}
	}
	pipelines: _
}
