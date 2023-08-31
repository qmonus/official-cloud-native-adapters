package azureCacheForRedis

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
	"qmonus.net/adapter/official/pulumi/base/random"
)

DesignPattern: {
	name: "sample:azureCacheForRedis"

	parameters: {
		appName: string
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClassicProvider: provider: "${AzureClassicProvider}"
	_randomProvider: provider:       "${RandomProvider}"

	resources: app: {
		redisNameSuffix: random.#Resource & {
			type:    "random:RandomString"
			options: _randomProvider
			properties: {
				length:  8
				special: false
			}
		}
		// Public redis
		redis: azure.#Resource & {
			type:    "azure:redis:Cache"
			options: _azureClassicProvider
			properties: {
				name:              "qvs-\(parameters.appName)-redis-${redisNameSuffix.result}"
				resourceGroupName: "${resourceGroup.name}"
				enableNonSslPort:  true
				location:          "japaneast"
				replicasPerMaster: 1
				shardCount:        1
				zones: ["1"]
				capacity: 1
				family:   "P"
				skuName:  "Premium"
				tags: "managed-by": "Qmonus Value Stream"
			}
		}
		// Firewall rule accessible from anywhere
		redisFirewallRule: azure.#Resource & {
			type: "azure:redis:FirewallRule"
			options: {
				_azureClassicProvider
			}
			properties: {
				name:              "qvs_redis_firewall_rule"
				redisCacheName:    "${redis.name}"
				resourceGroupName: "${resourceGroup.name}"
				startIp:           "0.0.0.0"
				endIp:             "255.255.255.255"
			}
		}
		redisPrimaryKeySecret: azure.#Resource & {
			type: "azure-native:keyvault:Secret"
			options: {
				dependsOn: ["${redis}", "${keyVaultAccessPolicyForQvs}"]
				_azureProvider
			}
			properties: {
				properties: {
					value: "${redis.primaryAccessKey}"
				}
				resourceGroupName: "${resourceGroup.name}"
				secretName:        "redisaccesskey"
				vaultName:         "${keyVault.name}"
			}
		}
	}
}
