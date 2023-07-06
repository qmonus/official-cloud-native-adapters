package random

import (
	"qmonus.net/adapter/official/pulumi/base/random"
)

DesignPattern: {
	name: "random:provider"

	parameters: {
		providerName: string | *"\(random.default.provider)"
	}

	resources: app: {
		"\(parameters.providerName)": random.#Resource & {
			// See the link below for the API detail.
			// https://www.pulumi.com/registry/packages/random/api-docs/provider/
			type: "pulumi:providers:random"
		}
	}
}
