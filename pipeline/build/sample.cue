package sample

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:compileDesignPattern"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
)

DesignPattern: {
	name: "deploy:sample"

	pipelineParameters: {
		useDebug:       bool | *false
		repositoryKind: string | *""
		resourcePriority: "high" | *"medium"
	}

	pipelines: {
		deploy: {
			tasks: {
				"checkout": gitCheckout.#Builder & {
					input: {
						repositoryKind: pipelineParameters.repositoryKind
					}
				}
				"compile": compileDesignPattern.#Builder & {
					input: {
						useDebug: pipelineParameters.useDebug
						resourcePriority: pipelineParameters.resourcePriority
					}
					runAfter: ["checkout"]
					approvalRequired: true
				}
				"deploy": deploymentWorker.#Builder & {
					runAfter: ["compile"]
				}
			}
		}
	}
}
