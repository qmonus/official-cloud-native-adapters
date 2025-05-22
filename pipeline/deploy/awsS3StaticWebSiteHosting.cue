package awsS3StaticWebSiteHosting

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:buildAwsS3StaticWebSiteHosting"
	"qmonus.net/adapter/official/pipeline/tasks:deployAwsS3StaticWebSiteHosting"
	"qmonus.net/adapter/official/pipeline/tasks:getUrlOfAwsCloudfrontDistribution"
	"qmonus.net/adapter/official/pipeline/tasks:generateEnvironmentVariablesFile"
)

DesignPattern: {
	name: "deploy:awsS3StaticWebSiteHosting"

	pipelineParameters: {
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}
	let _repositoryKind = pipelineParameters.repositoryKind
	let _useSshKey = pipelineParameters.useSshKey

	pipelines: {
		"publish-site": {
			tasks: {
				"checkout": {
					if _repositoryKind == "bitbucket" || _repositoryKind == "backlog" {
						gitCheckoutSsh.#Builder & {
							input: {
								repositoryKind: _repositoryKind
							}
						}
					}

					if _repositoryKind != "bitbucket" && _repositoryKind != "backlog" {
						if _useSshKey {
							gitCheckoutSsh.#Builder & {
								input: {
									repositoryKind: _repositoryKind
								}
							}
						}
						if !_useSshKey {
							gitCheckout.#Builder & {
								input: {
									repositoryKind: _repositoryKind
								}
							}
						}
					}
				}
				"generate-env-file": generateEnvironmentVariablesFile.#Builder & {
					runAfter: ["checkout"]
				}
				"build": buildAwsS3StaticWebSiteHosting.#Builder & {
					runAfter: ["generate-env-file"]
				}
				"deploy": deployAwsS3StaticWebSiteHosting.#Builder & {
					runAfter: ["build"]
				}
				"get-url": getUrlOfAwsCloudfrontDistribution.#Builder & {
					runAfter: ["deploy"]
				}
			}
			results: {
				"publicUrl":         tasks["get-url"].results.publicUrl
				"uploadedBucketUrl": tasks["deploy"].results.uploadedBucketUrl
			}
		}
	}
}
