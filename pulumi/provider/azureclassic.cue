package azureclassic

import (
	"qmonus.net/adapter/official/pulumi/base/azureclassic"
)

DesignPattern: {
	name: "azureclassic:provider"

	parameters: {
		providerName: string | *"\(azureclassic.default.provider)"
	}

	resources: app: {
		"\(parameters.providerName)": azureclassic.#Resource & {
			// See the link below for the API detail.
			// https://www.pulumi.com/registry/packages/azure/api-docs/provider/
			type: "pulumi:providers:azure"
		}
	}
}
