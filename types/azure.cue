package azure

import "qmonus.net/adapter/official/types:base"

#AzureProvider: {
	base.#Resource
	type: "pulumi:providers:azure-native"
}

#AzureClassicProvider: {
	base.#Resource
	type: "pulumi:providers:azure"
}

#AzureDnsRecordSet: {
	base.#Resource
	type: "azure-native:network:RecordSet"
	properties: metadata: base.#QvsManagedLabel
}

#AzureKeyVaultSecret: {
	base.#Resource
	type: "azure-native:keyvault:Secret"
	properties: tags: base.#QvsManagedLabel
}
