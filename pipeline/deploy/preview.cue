package preview

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPattern"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorkerPreview"
)

DesignPattern: {
	name: "deploy:preview"

	pipelineParameters: {
		useDebug:    bool | *false
		deployPhase: "app" | "setup" | *""
	}
	let _deployPhase = pipelineParameters.deployPhase
	let _useDebug = pipelineParameters.useDebug
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
				"checkout": gitCheckout.#Builder
				"compile":  compileDesignPattern.#Builder & {
					input: {
						phase:    _deployPhase
						useDebug: _useDebug
					}
					runAfter: ["checkout"]
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
						phase: _deployPhase
					}
					runAfter: ["deploy-preview"]
				}
			}
		}
	}
}
