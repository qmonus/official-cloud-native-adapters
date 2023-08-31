package tls

import (
	"qmonus.net/adapter/official/pulumi/base/tls"
)

DesignPattern: {
	name: "tls:provider"

	parameters: {
		providerName: string | *"\(tls.default.provider)"
	}

	resources: app: {
		"\(parameters.providerName)": tls.#Resource & {
			// See the link below for the API detail.
			// https://www.pulumi.com/registry/packages/tls/api-docs/provider/
			type: "pulumi:providers:tls"
		}
	}
}
