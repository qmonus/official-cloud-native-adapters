package appRunner

import (
	"qmonus.net/adapter/official/types:aws"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
	"qmonus.net/adapter/official/pipeline/sample:getUrlOfAwsAppRunner"
)

DesignPattern: {
	parameters: {
		serviceName: string
		imageUri:    string
		port:        string
		awsRegion:   string
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
			pattern: getUrlOfAwsAppRunner.DesignPattern
		},
	]

	let _awsProvider = "awsProvider"
	let _appRunnerService = "appRunnerService"

	resources: app: {
		"\(_awsProvider)": aws.#AwsProvider & {
			properties: {
				region: parameters.awsRegion
			}
		}

		"\(_appRunnerService)": aws.#AwsAppRunnerService & {
			options: {
				provider: "${\(_awsProvider)}"
			}
			properties: {
				serviceName: parameters.serviceName
				sourceConfiguration: {
					imageRepository: {
						imageConfiguration: {
							port: parameters.port
						}
						imageIdentifier:     parameters.imageUri
						imageRepositoryType: "ECR_PUBLIC"
					}
					autoDeploymentsEnabled: false
				}
			}
		}
	}

	pipelines: _
}
