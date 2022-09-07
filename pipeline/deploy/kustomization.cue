package kustomization

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:kustomization"
	"qmonus.net/adapter/official/pipeline/tasks:deploymentWorker"
)

DesignPattern: {
	name: "deploy:kustomization"

	pipelines: {
		"deploy": {
			tasks: {
				"checkout": gitCheckout.#Builder
				"compile":  kustomization.#Builder & {
					runAfter: ["checkout"]
				}
				"deploy": deploymentWorker.#Builder & {
					runAfter: ["compile"]
				}
			}
		}
	}
}
