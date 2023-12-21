package bluegreen

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPattern"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPatternSsh"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
	"qmonus.net/adapter/official/pipeline/tasks:checkRolloutStatus"
	"qmonus.net/adapter/official/pipeline/tasks:promoteRollout"
)

DesignPattern: {
	name: "deploy:bluegreen"

	pipelineParameters: {
		repositoryKind:   string | *""
		useDebug:         bool | *false
		resourcePriority: "high" | *"medium"
		useSshKey:        bool | *false
	}
	let _repositoryKind = pipelineParameters.repositoryKind
	let _useDebug = pipelineParameters.useDebug
	let _resourcePriority = pipelineParameters.resourcePriority
	let _useSshKey = pipelineParameters.useSshKey

	pipelines: {
		"deploy": {
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
				"compile": {
					if _repositoryKind == "bitbucket" || _repositoryKind == "backlog" {
						compileDesignPatternSsh.#Builder & {
							input: {
								useDebug:         _useDebug
								resourcePriority: _resourcePriority
							}
							runAfter: ["checkout"]
						}
					}

					if _repositoryKind != "bitbucket" && _repositoryKind != "backlog" {
						if _useSshKey {
							compileDesignPatternSsh.#Builder & {
								input: {
									useDebug:         _useDebug
									resourcePriority: _resourcePriority
								}
								runAfter: ["checkout"]
							}
						}
						if !_useSshKey {
							compileDesignPattern.#Builder & {
								input: {
									useDebug:         _useDebug
									resourcePriority: _resourcePriority
								}
								runAfter: ["checkout"]
							}
						}
					}
				}
				"deploy": deploymentWorker.#Builder & {
					input: {
						resourcePriority: _resourcePriority
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
		"release": {
			tasks: {
				"wait-for-preview": checkRolloutStatus.#Builder & {
					input: {
						constParams: {
							expectedStatus: "Healthy,Paused"
						}
					}
					prefix:           "preview"
					approvalRequired: true
				}
				"promote": promoteRollout.#Builder & {
					runAfter: ["wait-for-preview"]
				}
				"wait-for-active": checkRolloutStatus.#Builder & {
					input: {
						constParams: {
							expectedStatus: "Healthy"
						}
					}
					prefix: "active"
					runAfter: ["promote"]
				}
			}
		}
	}
}
