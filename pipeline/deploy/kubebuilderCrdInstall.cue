package kubebuilderCrdInstall

import (
	"qmonus.net/adapter/official/pipeline/tasks:kubebuilderCrdInstall"
)

DesignPattern: {
	name: "deploy:kubebuilderCrdInstall"

	pipelines: {
		"deploy": {
			tasks: {
				"crd-install": kubebuilderCrdInstall.#Builder & {
					runAfter: ["checkout"]
				}
			}
		}
	}
}
