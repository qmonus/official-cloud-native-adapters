package azureWebAppForContainers

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureWebAppForContainers"

	parameters: {
		appName:                       string
		azureSubscriptionId:           string
		azureResourceGroupName:        string
		azureDnsZoneResourceGroupName: string
		containerRegistryName:         string
		dnsZoneName:                   string
		subDomainName:                 string | *"api"
		subnetId:                      string | *""
		dbHost:                        string
		redisHost:                     string
		azureKeyVaultName:             string
		imageFullNameTag:              string
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClassicProvider: provider: "${AzureClassicProvider}"

	resources: app: {
		webAppForContainer: azure.#Resource & {
			type:    "azure-native:web:WebApp"
			options: _azureProvider
			options: ignoreChanges: [
				"hostNameSslStates",
			]
			properties: {
				name:              "qvs-\(parameters.appName)-web-app"
				resourceGroupName: parameters.azureResourceGroupName
				kind:              "app,linux,container"
				location:          "japaneast"
				reserved:          true
				serverFarmId:      "${appServicePlan.id}"
				if parameters.subnetId != "" {
					virtualNetworkSubnetId: parameters.subnetId
				}
				siteConfig: {
					appSettings: [
						{
							name:  "PORT"
							value: "80"
						},
						{
							name:  "DB_HOST"
							value: parameters.dbHost
						},
						{
							name:  "DB_USER"
							value: "admin_user"
						},
						{
							name: "DB_PASS"
							value: {
								"fn::secret": {
									"fn::invoke": {
										function: "azure:keyvault:getSecret"
										arguments: {
											name:       "dbadminpassword"
											keyVaultId: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/\(parameters.azureResourceGroupName)/providers/Microsoft.KeyVault/vaults/\(parameters.azureKeyVaultName)"
										}
										return: "value"
									}
								}
							}
						},
						{
							name:  "REDIS_HOST"
							value: parameters.redisHost
						},
						{
							name: "REDIS_PASS"
							value: {
								"fn::secret": {
									"fn::invoke": {
										function: "azure:keyvault:getSecret"
										arguments: {
											name:       "redisaccesskey"
											keyVaultId: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/\(parameters.azureResourceGroupName)/providers/Microsoft.KeyVault/vaults/\(parameters.azureKeyVaultName)"
										}
										return: "value"
									}
								}
							}
						},
						{
							name:  "REDIS_PORT"
							value: "6380"
						},
						{
							name: "DOCKER_REGISTRY_SERVER_URL"
							value: {
								"fn::invoke": {
									function: "azure:containerservice:getRegistry"
									arguments: {
										name:              parameters.containerRegistryName
										resourceGroupName: parameters.azureResourceGroupName
									}
									return: "loginServer"
								}
							}
						},
						{
							name: "DOCKER_REGISTRY_SERVER_USERNAME"
							value: {
								"fn::invoke": {
									function: "azure:containerservice:getRegistry"
									arguments: {
										name:              parameters.containerRegistryName
										resourceGroupName: parameters.azureResourceGroupName
									}
									return: "adminUsername"
								}
							}
						},
						{
							name: "DOCKER_REGISTRY_SERVER_PASSWORD"
							value: {
								"fn::invoke": {
									function: "azure:containerservice:getRegistry"
									arguments: {
										name:              parameters.containerRegistryName
										resourceGroupName: parameters.azureResourceGroupName
									}
									return: "adminPassword"
								}
							}
						},
					]
					alwaysOn:        true
					linuxFxVersion:  "DOCKER|\(parameters.imageFullNameTag)"
					numberOfWorkers: 1
				}
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		cnameRecord: azure.#Resource & {
			type:    "azure-native:network:RecordSet"
			options: _azureProvider
			properties: {
				resourceGroupName: parameters.azureDnsZoneResourceGroupName
				recordType:        "CNAME"
				cnameRecord: cname: "${webAppForContainer.defaultHostName}"
				relativeRecordSetName: parameters.subDomainName
				ttl:                   3600
				zoneName:              parameters.dnsZoneName
				metadata: "managed-by": "Qmonus Value Stream"
			}
		}

		txtRecord: azure.#Resource & {
			type:    "azure-native:network:RecordSet"
			options: _azureProvider
			properties: {
				resourceGroupName: parameters.azureDnsZoneResourceGroupName
				recordType:        "TXT"
				txtRecords: [{
					value: [
						"${webAppForContainer.customDomainVerificationId}",
					]
				}]
				relativeRecordSetName: "asuid.\(parameters.subDomainName)"
				ttl:                   3600
				zoneName:              parameters.dnsZoneName
				metadata: "managed-by": "Qmonus Value Stream"
			}
		}

		webAppHostNameBinding: azure.#Resource & {
			type:    "azure-native:web:WebAppHostNameBinding"
			options: _azureProvider
			options: ignoreChanges: [
				"sslState",
				"thumbprint",
			]
			properties: {
				name:                        "${webAppForContainer.name}"
				resourceGroupName:           parameters.azureResourceGroupName
				customHostNameDnsRecordType: "CName"
				hostName: {
					"fn::invoke": {
						function: "str:trimSuffix"
						arguments: {
							string: "${cnameRecord.fqdn}"
							suffix: "."
						}
						return: "result"
					}
				}
			}
		}

		managedCertificate: azure.#Resource & {
			type:    "azure:appservice:ManagedCertificate"
			options: _azureClassicProvider
			properties: {
				customHostnameBindingId: "${webAppHostNameBinding.id}"
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		certBinding: azure.#Resource & {
			type:    "azure:appservice:CertificateBinding"
			options: _azureClassicProvider
			properties: {
				certificateId:     "${managedCertificate.id}"
				hostnameBindingId: "${webAppHostNameBinding.id}"
				sslState:          "SniEnabled"
			}
		}
	}
}
