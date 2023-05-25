package kustomization

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:kustomization"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
)

DesignPattern: {
	name: "deploy:kustomization"

	pipelineParameters: {
		resourcePriority: "high" | *"medium"
		repositoryKind:   string | *""
	}

	pipelines: {
		"deploy": {
			tasks: {
				"checkout": gitCheckout.#Builder & {
					input: {
						repositoryKind: pipelineParameters.repositoryKind
					}
				}
				"compile": kustomization.#Builder & {
					runAfter: ["checkout"]
				}
				"deploy": deploymentWorker.#Builder & {
					input: {
						resourcePriority: pipelineParameters.resourcePriority
					}
					runAfter: ["compile"]
				}
			}
		}
	}
}
