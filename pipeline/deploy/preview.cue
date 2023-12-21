package preview

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPattern"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPatternSsh"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorkerPreview"
)

DesignPattern: {
	name: "deploy:preview"

	pipelineParameters: {
		repositoryKind:   string | *""
		useDebug:         bool | *false
		deployPhase:      "app" | "setup" | *""
		resourcePriority: "high" | *"medium"
		useSshKey:        bool | *false
	}
	let _repositoryKind = pipelineParameters.repositoryKind
	let _useDebug = pipelineParameters.useDebug
	let _deployPhase = pipelineParameters.deployPhase
	let _resourcePriority = pipelineParameters.resourcePriority
	let _useSshKey = pipelineParameters.useSshKey
	let _stage = {
		if _deployPhase == "setup" {
			_deployPhase
		}
		if _deployPhase != "setup" {
			"deploy-preview"
		}
	}

	pipelines: {
		"\(_stage)": {
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
								phase:            _deployPhase
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
									phase:            _deployPhase
									useDebug:         _useDebug
									resourcePriority: _resourcePriority
								}
								runAfter: ["checkout"]
							}
						}
						if !_useSshKey {
							compileDesignPattern.#Builder & {
								input: {
									phase:            _deployPhase
									useDebug:         _useDebug
									resourcePriority: _resourcePriority
								}
								runAfter: ["checkout"]
							}
						}
					}
				}
				"deploy-preview": deploymentWorkerPreview.#Builder & {
					input: {
						phase: _deployPhase
					}
					runAfter: ["compile"]
					approvalRequired: true
				}
				"deploy-after-approval": deploymentWorker.#Builder & {
					input: {
						phase:            _deployPhase
						resourcePriority: _resourcePriority
					}
					runAfter: ["deploy-preview"]
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
