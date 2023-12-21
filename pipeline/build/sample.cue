package sample

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPattern"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
)

DesignPattern: {
	name: "deploy:sample"

	pipelineParameters: {
		useDebug:         bool | *false
		repositoryKind:   string | *""
		resourcePriority: "high" | *"medium"
		useSshKey:        bool | *false
	}

	pipelines: {
		deploy: {
			tasks: {
				"checkout": {
					let _repositoryKind = pipelineParameters.repositoryKind
					let _useSshKey = pipelineParameters.useSshKey

					if _repositoryKind == "bitbucket" {
						gitCheckoutSsh.#Builder & {
							input: {
								repositoryKind: _repositoryKind
							}
						}
					}

					if _repositoryKind != "bitbucket" {
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
				"compile": compileDesignPattern.#Builder & {
					input: {
						useDebug:         pipelineParameters.useDebug
						resourcePriority: pipelineParameters.resourcePriority
					}
					runAfter: ["checkout"]
					approvalRequired: true
				}
				"deploy": deploymentWorker.#Builder & {
					input: {
						resourcePriority: pipelineParameters.resourcePriority
					}
					runAfter: ["compile"]
				}
			}
			results: {
				module:          tasks["compile"].results.module
				adapterRevision: tasks["compile"].results.adapterRevision
				adapters:        tasks["compile"].results.adapters
			}
		}
	}
}
