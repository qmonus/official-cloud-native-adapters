package azureCacheForRedis

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:random"
)

DesignPattern: {
	parameters: {
		appName: string
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClassicProvider: provider: "${AzureClassicProvider}"
	_randomProvider: provider:       "${RandomProvider}"

	resources: app: {
		redisNameSuffix: random.#RandomString & {
			options: _randomProvider
			properties: {
				length:  8
				special: false
			}
		}
		// Public redis
		redis: azure.#AzureCacheForRedis & {
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
			}
		}
		// Firewall rule accessible from anywhere
		redisFirewallRule: azure.#AzureRedisFirewallRule & {
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
		redisPrimaryKeySecret: azure.#AzureKeyVaultSecret & {
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
