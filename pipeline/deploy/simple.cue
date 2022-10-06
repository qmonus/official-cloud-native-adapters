package simple

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPattern"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
)

DesignPattern: {
	name: "deploy:simple"

	pipelineParameters: {
		useDebug:    bool | *false
		deployPhase: "app" | "setup" | *""
		resourcePriority: "high" | *"medium"
	}
	let _deployPhase = pipelineParameters.deployPhase
	let _useDebug = pipelineParameters.useDebug
	let _resourcePriority = pipelineParameters.resourcePriority
	let _stage = {
		if _deployPhase == "setup" {
			_deployPhase
		}
		if _deployPhase != "setup" {
			"deploy"
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
						resourcePriority: _resourcePriority
					}
					runAfter: ["checkout"]
				}
				"deploy": deploymentWorker.#Builder & {
					input: {
						phase: _deployPhase
					}
					runAfter: ["compile"]
				}
			}
		}
	}
}
