package azure

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "azure:provider"

	parameters: {
		providerName: string | *"\(azure.default.provider)"
	}

	resources: app: {
		"\(parameters.providerName)": azure.#Resource & {
			// See the link below for the API detail.
			// https://www.pulumi.com/registry/packages/azure-native/api-docs/provider/
			type: "pulumi:providers:azure-native"
		}
	}
}
