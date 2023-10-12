package azureStaticWebApps

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:buildAzureStaticWebApps"
	"qmonus.net/adapter/official/pipeline/tasks:deployAzureStaticWebApps"
	"qmonus.net/adapter/official/pipeline/tasks:getUrlOfAzureStaticWebApps"
)

DesignPattern: {
	name: "deploy:azureStaticWebApps"

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
				"build": buildAzureStaticWebApps.#Builder & {
					runAfter: ["checkout"]
				}
				"deploy": deployAzureStaticWebApps.#Builder & {
					runAfter: ["build"]
				}
				"get-url": getUrlOfAzureStaticWebApps.#Builder & {
					runAfter: ["deploy"]
				}
			}
			results: {
				"publicUrl": tasks["get-url"].results.publicUrl
			}
		}
	}
}
