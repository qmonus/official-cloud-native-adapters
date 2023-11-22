package azureWebAppForContainers

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:base"

	"list"
	"strings"
)

DesignPattern: {
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
		args?: [...string]
		environmentVariables: [string]: string
		secrets: [string]:              base.#Secret
		appServiceAllowedSourceIps: [...string] | *[]
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClassicProvider: provider: "${AzureClassicProvider}"
	_keyvaultId: "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/\(parameters.azureResourceGroupName)/providers/Microsoft.KeyVault/vaults/\(parameters.azureKeyVaultName)"

	resources: app: {
		webAppForContainer: azure.#AzureWebApp & {
			options: _azureProvider
			options: ignoreChanges: [
				"hostNameSslStates",
			]

			#envData: {
				name:  string
				value: _
			}
			let _envData = [
				for n, v in parameters.environmentVariables {
					#envData & {
						name:  n
						value: v
					}
				},
			]
			let _secretData = [
				for n, s in parameters.secrets {
					#envData & {
						name:  n
						value: "@Microsoft.KeyVault(VaultName=\(parameters.azureKeyVaultName);SecretName=\(s.key))"
					}
				},
			]

			_envElems: [...#envData] &
				_envData+_secretData+[{
					name:  "PORT"
					value: "80"
				}, {
					name:  "DB_HOST"
					value: parameters.dbHost
				}, {
					name:  "DB_USER"
					value: "admin_user"
				}, {
					name:  "DB_PASS"
					value: "@Microsoft.KeyVault(VaultName=\(parameters.azureKeyVaultName);SecretName=dbadminpassword)"
				}, {
					name:  "REDIS_HOST"
					value: parameters.redisHost
				}, {
					name:  "REDIS_PASS"
					value: "@Microsoft.KeyVault(VaultName=\(parameters.azureKeyVaultName);SecretName=redisaccesskey)"
				}, {
					name:  "REDIS_PORT"
					value: "6380"
				}, {
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
				}, {
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
				}, {
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
				}]
			_envSet: [string]: #envData
			_envSet: {
				for e in _envElems {
					"\(e.name)": e
				}
			}
			_uniqEnvData: [ for s in _envSet {s}]
			// sort with name to make results deterministic
			let _envDataSorted = list.Sort(_uniqEnvData, {x: {}, y: {}, less: x.name < y.name})

			properties: {
				name:              "qvs-\(parameters.appName)-web-app"
				resourceGroupName: parameters.azureResourceGroupName
				kind:              "app,linux,container"
				location:          "japaneast"
				reserved:          true
				serverFarmId:      "${appServicePlan.id}"
				identity: {
					type: "UserAssigned"
					userAssignedIdentities: [
						"${webAppUserAssignedIdentity.id}",
					]
				}
				keyVaultReferenceIdentity: "${webAppUserAssignedIdentity.id}"
				if parameters.subnetId != "" {
					virtualNetworkSubnetId: parameters.subnetId
				}
				siteConfig: {
					appSettings:     _envDataSorted
					alwaysOn:        true
					linuxFxVersion:  "DOCKER|\(parameters.imageFullNameTag)"
					numberOfWorkers: 1
					if parameters.args != _|_ {
						appCommandLine: strings.Join(parameters.args, " ")
					}

					// if there is no user-specified acl, default acl is set
					if len(parameters.appServiceAllowedSourceIps) == 0 {
						ipSecurityRestrictionsDefaultAction: "Allow"
					}
					if len(parameters.appServiceAllowedSourceIps) > 0 {
						ipSecurityRestrictionsDefaultAction: "Deny"
						ipSecurityRestrictions: [
							for i, ip in parameters.appServiceAllowedSourceIps {
								{
									name:      "Managed by Qmonus Value Stream"
									action:    "Allow"
									priority:  2000 + i
									ipAddress: ip
								}
							},
						]
					}
				}
			}
		}

		webAppUserAssignedIdentity: azure.#AzureUserAssignedIdentity & {
			options: _azureProvider
			properties: {
				location:          "japaneast"
				resourceGroupName: parameters.azureResourceGroupName
				resourceName:      "qvs-\(parameters.appName)-web-app-user-assigned-identity"
			}
		}

		keyVaultAccessPolicyForWebApp: azure.#AzureKeyVaultAccessPolicy & {
			options: _azureClassicProvider
			properties: {
				keyVaultId: _keyvaultId
				tenantId: "fn::invoke": {
					function: "azure-native:authorization:getClientConfig"
					return:   "tenantId"
				}
				objectId: "${webAppUserAssignedIdentity.principalId}"
				secretPermissions: ["Get"]
			}
		}

		cnameRecord: azure.#AzureClassicCNameRecord & {
			options: _azureClassicProvider
			properties: {
				resourceGroupName: parameters.azureDnsZoneResourceGroupName
				record:            "${webAppForContainer.defaultHostName}"
				name:              parameters.subDomainName
				ttl:               3600
				zoneName:          parameters.dnsZoneName
			}
		}

		txtRecord: azure.#AzureDnsRecordSet & {
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
			}
		}

		webAppHostNameBinding: azure.#AzureWebAppHostNameBinding & {
			options: _azureProvider
			options: dependsOn: ["${txtRecord}"]
			options: ignoreChanges: [
				"sslState",
				"thumbprint",
			]
			properties: {
				name:                        "${webAppForContainer.name}"
				resourceGroupName:           parameters.azureResourceGroupName
				customHostNameDnsRecordType: "CName"
				azureResourceType:           "Website"
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

		managedCertificate: azure.#AzureManagedCertificate & {
			options: _azureClassicProvider
			options: dependsOn: ["${cnameRecord}"]
			properties: {
				customHostnameBindingId: "${webAppHostNameBinding.id}"
			}
		}

		certBinding: azure.#AzureCertificateBinding & {
			options: _azureClassicProvider
			properties: {
				certificateId:     "${managedCertificate.id}"
				hostnameBindingId: "${webAppHostNameBinding.id}"
				sslState:          "SniEnabled"
			}
		}
	}
}
