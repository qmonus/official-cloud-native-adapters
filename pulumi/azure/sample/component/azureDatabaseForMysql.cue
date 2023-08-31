package azureDatabaseForMysql

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
	"qmonus.net/adapter/official/pulumi/base/random"
)

DesignPattern: {
	name: "sample:azureDatabaseForMysql"

	parameters: {
		appName:      string
		mysqlSkuName: string | *"B_Standard_B2s"
		mysqlVersion: string | *"8.0.21"
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClassicProvider: provider: "${AzureClassicProvider}"
	_randomProvider: provider:       "${RandomProvider}"

	resources: app: {
		mysqlNameSuffix: random.#Resource & {
			type:    "random:RandomString"
			options: _randomProvider
			properties: {
				length:  8
				special: false
				upper:   false
			}
		}

		// Public mysql database
		mysql: azure.#Resource & {
			type: "azure:mysql:FlexibleServer"
			options: {
				_azureClassicProvider
			}
			properties: {
				name:                  "qvs-\(parameters.appName)-mysql-${mysqlNameSuffix.result}"
				resourceGroupName:     "${resourceGroup.name}"
				location:              "japaneast"
				administratorLogin:    "admin_user"
				administratorPassword: "${mysqlAdminPassword.result}"
				skuName:               parameters.mysqlSkuName
				version:               parameters.mysqlVersion
				createMode:            "Default"
				zone:                  "2"
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		// Firewall rule accessible from anywhere
		mysqlFirewallRule: azure.#Resource & {
			type: "azure:mysql:FlexibleServerFirewallRule"
			options: {
				_azureClassicProvider
			}
			properties: {
				name:              "qvs-mysql-firewall-rule"
				resourceGroupName: "${resourceGroup.name}"
				serverName:        "${mysql.name}"
				startIpAddress:    "0.0.0.0"
				endIpAddress:      "255.255.255.255"
			}
		}

		mysqlAdminPassword: random.#Resource & {
			type:    "random:RandomPassword"
			options: _randomProvider
			properties: {
				length:     16
				minLower:   1
				minNumeric: 1
				minSpecial: 1
				minUpper:   1
			}
		}

		mysqlAdminUserSecret: azure.#Resource & {
			type: "azure-native:keyvault:Secret"
			options: {
				dependsOn: ["${keyVaultAccessPolicyForQvs}"]
				_azureProvider
			}
			properties: {
				properties: {
					value: "admin_user"
				}
				resourceGroupName: "${resourceGroup.name}"
				secretName:        "dbadminuser"
				vaultName:         "${keyVault.name}"
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		mysqlAdminPasswordSecret: azure.#Resource & {
			type: "azure-native:keyvault:Secret"
			options: {
				dependsOn: ["${keyVaultAccessPolicyForQvs}"]
				_azureProvider
			}
			properties: {
				properties: {
					value: "${mysqlAdminPassword.result}"
				}
				resourceGroupName: "${resourceGroup.name}"
				secretName:        "dbadminpassword"
				vaultName:         "${keyVault.name}"
				tags: "managed-by": "Qmonus Value Stream"
			}
		}
	}
}
