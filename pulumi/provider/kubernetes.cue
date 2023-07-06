package kubernetes

import (
	"qmonus.net/adapter/official/pulumi/base/kubernetes"
)

DesignPattern: {
	name: "kubernetes:provider"

	parameters: {
		providerName: string | *"\(kubernetes.default.provider)"
	}

	resources: app: {
		"\(parameters.providerName)": kubernetes.#Resource & {
			// See the link below for the API detail.
			// https://www.pulumi.com/registry/packages/kubernetes/api-docs/provider/
			type: "pulumi:providers:kubernetes"
		}
	}
}
