package azureKeyVault

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:random"
)

DesignPattern: {
	parameters: {
		keyVaultAccessAllowedObjectIds: [...string]
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClassicProvider: provider: "${AzureClassicProvider}"
	_randomProvider: provider:       "${RandomProvider}"

	resources: app: {
		vaultNameSuffix: random.#RandomString & {
			options: _randomProvider
			properties: {
				length:  8
				special: false
			}
		}

		keyVault: azure.#AzureKeyVault & {
			options: {
				_azureProvider

				// Ignore vault rewriting access policies
				ignoreChanges: ["properties.accessPolicies"]
			}
			properties: {
				vaultName:         "qvs-key-vault-${vaultNameSuffix.result}"
				resourceGroupName: "${resourceGroup.name}"
				location:          "japaneast"
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

		keyVaultAccessPolicyForQvs: azure.#AzureKeyVaultAccessPolicy & {
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
			"keyVaultAccessPolicyForUser\(x+1)": azure.#AzureKeyVaultAccessPolicy & {
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
