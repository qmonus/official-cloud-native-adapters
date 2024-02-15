package gcpFirebaseHosting

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:buildGcpFirebaseHosting"
	"qmonus.net/adapter/official/pipeline/tasks:deployGcpFirebaseHosting"
	"qmonus.net/adapter/official/pipeline/tasks:getUrlOfGcpFirebaseHosting"
	"qmonus.net/adapter/official/pipeline/tasks:generateEnvironmentVariablesFile"
)

DesignPattern: {
	name: "deploy:gcpFirebaseHosting"

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
				"build": buildGcpFirebaseHosting.#Builder & {
					runAfter: ["generate-env-file"]
				}
				"get-url": getUrlOfGcpFirebaseHosting.#Builder & {
					runAfter: ["build"]
				}
				"deploy": deployGcpFirebaseHosting.#Builder & {
					runAfter: ["get-url"]
				}
			}
			results: {
				"defaultDomain": tasks["get-url"].results.defaultDomain
				"customDomain":  tasks["get-url"].results.customDomain
			}
		}
	}
}
