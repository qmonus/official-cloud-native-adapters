package azureApiBackendApplicationAdapterForAzureResources

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
	"qmonus.net/adapter/official/pulumi/base/mysql"
	"qmonus.net/adapter/official/pulumi/base/random"

	"strconv"
)

DesignPattern: {
	name: "azure:azureApiBackendApplicationAdapterForAzureResources"

	parameters: {
		appName:                                string
		azureProvider:                          string | *"\(azure.default.provider)"
		mysqlProvider:                          string | *"\(mysql.default.provider)"
		azureSubscriptionId:                    string
		azureResourceGroupName:                 string
		azureDnsZoneName:                       string
		azureDnsARecordName:                    string
		azureStaticIpAddress:                   string
		azureARecordTtl:                        string | *"3600"
		mysqlCreateUserName:                    string | *"dbuser"
		mysqlCreateDbName:                      string
		mysqlCreateDbCharacterSet:              string | *"utf8mb3"
		mysqlEndpoint:                          string
		azureKeyVaultKeyContainerName:          string
		azureKeyVaultDbAdminSecretName:         string | *"dbadminuser"
		azureKeyVaultDbAdminPasswordSecretName: string | *"dbadminpassword"
		azureKeyVaultDbUserSecretName:          string | *"dbuser"
		azureKeyVaultDbPasswordSecretName:      string | *"dbpassword"
	}

	group:   string
	_prefix: string | *""
	if group != _|_ {
		_prefix: "\(group)/"
	}
	let _suffix = parameters.appName

	let _aRecord = "\(_prefix)aRecord/\(_suffix)"
	let _database = "\(_prefix)database/\(_suffix)"
	let _user = "\(_prefix)user/\(_suffix)"
	let _grant = "\(_prefix)grant/\(_suffix)"
	let _dbUserSecret = "\(_prefix)dbUserSecret/\(_suffix)"
	let _dbPasswordSecret = "\(_prefix)dbPasswordSecret/\(_suffix)"
	let _dbRandomPassword = "\(_prefix)dbRandomPassword/\(_suffix)"

	resources: app: {
		"\(_aRecord)": azure.#Resource & {
			type: "azure-native:network:RecordSet"
			options: provider: "${\(parameters.azureProvider)}"
			properties: {
				recordType:            "A"
				resourceGroupName:     parameters.azureResourceGroupName
				zoneName:              parameters.azureDnsZoneName
				relativeRecordSetName: parameters.azureDnsARecordName
				aRecords: [{ipv4Address: parameters.azureStaticIpAddress}]
				ttl: strconv.Atoi(parameters.azureARecordTtl)
				metadata:
					"managed-by": "Qmonus Value Stream"
			}
		}

		"\(parameters.mysqlProvider)": mysql.#Resource & {
			properties: {
				endpoint: parameters.mysqlEndpoint
				username: {
					"fn::secret": {
						"fn::invoke": {
							function: "azure:keyvault:getSecret"
							arguments: {
								name:       parameters.azureKeyVaultDbAdminSecretName
								keyVaultId: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/\(parameters.azureResourceGroupName)/providers/Microsoft.KeyVault/vaults/\(parameters.azureKeyVaultKeyContainerName)"
							}
							return: "value"
						}
					}
				}
				password: {
					"fn::secret": {
						"fn::invoke": {
							function: "azure:keyvault:getSecret"
							arguments: {
								name:       parameters.azureKeyVaultDbAdminPasswordSecretName
								keyVaultId: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/\(parameters.azureResourceGroupName)/providers/Microsoft.KeyVault/vaults/\(parameters.azureKeyVaultKeyContainerName)"
							}
							return: "value"
						}
					}
				}
				tls: "skip-verify"
			}
		}

		"\(_database)": mysql.#Resource & {
			options: provider: "${\(parameters.mysqlProvider)}"
			type: "mysql:Database"
			properties: {
				name:                parameters.mysqlCreateDbName
				defaultCharacterSet: parameters.mysqlCreateDbCharacterSet
			}
		}

		"\(_user)": mysql.#Resource & {
			options: provider: "${\(parameters.mysqlProvider)}"
			type: "mysql:User"
			properties: {
				user:              parameters.mysqlCreateUserName
				host:              "%"
				plaintextPassword: "${\(_dbRandomPassword).result}"
			}
		}

		"\(_grant)": mysql.#Resource & {
			options: {
				provider: "${\(parameters.mysqlProvider)}"
				dependsOn: ["${\(_database)}", "${\(_user)}"]
			}
			type: "mysql:Grant"
			properties: {
				database: parameters.mysqlCreateDbName
				user:     parameters.mysqlCreateUserName
				host:     "%"
				privileges: ["ALL"]
				table: "*"
			}
		}

		"\(_dbUserSecret)": azure.#Resource & {
			options: {
				provider: "${\(parameters.azureProvider)}"
			}
			type: "azure-native:keyvault:Secret"
			properties: {
				properties: {
					value: parameters.mysqlCreateUserName
				}
				resourceGroupName: parameters.azureResourceGroupName
				vaultName:         parameters.azureKeyVaultKeyContainerName
				secretName:        parameters.azureKeyVaultDbUserSecretName
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		"\(_dbPasswordSecret)": azure.#Resource & {
			options: {
				provider: "${\(parameters.azureProvider)}"
			}
			type: "azure-native:keyvault:Secret"
			properties: {
				properties: {
					value: "${\(_dbRandomPassword).result}"
				}
				resourceGroupName: parameters.azureResourceGroupName
				vaultName:         parameters.azureKeyVaultKeyContainerName
				secretName:        parameters.azureKeyVaultDbPasswordSecretName
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		"\(_dbRandomPassword)": random.#Resource & {
			type: "random:RandomPassword"
			properties: {
				length:     16
				minLower:   1
				minUpper:   1
				minNumeric: 1
				special:    false
			}
		}
	}
}
