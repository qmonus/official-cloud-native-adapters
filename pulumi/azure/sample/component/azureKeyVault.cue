package azureKeyVault

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
	"qmonus.net/adapter/official/pulumi/base/random"
)

DesignPattern: {
	name: "sample:azureKeyVault"

	parameters: {
		keyVaultAccessAllowedObjectIds: [...string]
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClassicProvider: provider: "${AzureClassicProvider}"
	_randomProvider: provider:       "${RandomProvider}"

	resources: app: {
		vaultNameSuffix: random.#Resource & {
			type:    "random:RandomString"
			options: _randomProvider
			properties: {
				length:  8
				special: false
			}
		}

		keyVault: azure.#Resource & {
			type: "azure-native:keyvault:Vault"
			options: {
				_azureProvider

				// Ignore vault rewriting access policies
				ignoreChanges: ["properties.accessPolicies"]
			}
			properties: {
				vaultName:         "qvs-key-vault-${vaultNameSuffix.result}"
				resourceGroupName: "${resourceGroup.name}"
				location:          "japaneast"
				tags: "managed-by": "Qmonus Value Stream"
				properties: {
					accessPolicies: []
					tenantId:
						"fn::invoke": {
							function: "azure-native:authorization:getClientConfig"
							return:   "tenantId"
						}
					enableRbacAuthorization:      false
					enableSoftDelete:             true
					enabledForDeployment:         false
					enabledForDiskEncryption:     false
					enabledForTemplateDeployment: false
					sku: {
						family: "A"
						name:   "standard"
					}
					softDeleteRetentionInDays: 90
				}
			}
		}

		keyVaultAccessPolicyForQvs: azure.#Resource & {
			type:    "azure:keyvault:AccessPolicy"
			options: _azureClassicProvider
			properties: {
				keyVaultId: "${keyVault.id}"
				tenantId: "fn::invoke": {
					function: "azure-native:authorization:getClientConfig"
					return:   "tenantId"
				}
				objectId: "fn::invoke": {
					function: "azure-native:authorization:getClientConfig"
					return:   "objectId"
				}
				secretPermissions: ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
			}
		}

		for x, n in parameters.keyVaultAccessAllowedObjectIds {
			"keyVaultAccessPolicyForUser\(x+1)": azure.#Resource & {
				type:    "azure:keyvault:AccessPolicy"
				options: _azureClassicProvider
				properties: {
					keyVaultId: "${keyVault.id}"
					tenantId: "fn::invoke": {
						function: "azure-native:authorization:getClientConfig"
						return:   "tenantId"
					}
					objectId: n
					secretPermissions: ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
				}
			}
		}
	}
}
