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
				"generate-environment-variables-file": generateEnvironmentVariablesFile.#Builder & {
					runAfter: ["checkout"]
				}
				"build-gcp-firebase-hosting": buildGcpFirebaseHosting.#Builder & {
					runAfter: ["generate-environment-variables-file"]
				}
				"get-url-gcp-firebase-hosting": getUrlOfGcpFirebaseHosting.#Builder & {
					runAfter: ["build-gcp-firebase-hosting"]
				}
				"deploy-gcp-firebase-hosting": deployGcpFirebaseHosting.#Builder & {
					runAfter: ["get-url-gcp-firebase-hosting"]
				}
			}
			results: {
				"defaultDomain": tasks["get-url-gcp-firebase-hosting"].results.defaultDomain
				"customDomain":  tasks["get-url-gcp-firebase-hosting"].results.customDomain
			}
		}
	}
}
