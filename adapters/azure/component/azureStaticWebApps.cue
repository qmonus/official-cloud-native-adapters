package azureStaticWebApps

import (
	"strconv"

	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:base"
)

DesignPattern: {
	parameters: {
		appName:                       string
		azureStaticSiteLocation:       string | *"East Asia"
		azureSubscriptionId:           string
		azureResourceGroupName:        string
		azureDnsZoneResourceGroupName: string
		azureDnsZoneName:              string
		relativeRecordSetName:         string | *"www"
		azureCnameRecordTtl:           string | *"3600"
	}

	_azureProvider: provider: "${AzureProvider}"

	let _staticSite = "staticSite"
	let _cnameRecord = "cnameRecord"
	let _waitCnamePropagation = "waitCnamePropagation"
	let _staticSiteCustomDomain = "staticSiteCustomDomain"

	resources: app: {
		"\(_staticSite)": azure.#AzureStaticSite & {
			options: _azureProvider
			properties: {
				resourceGroupName: parameters.azureResourceGroupName
				location:          parameters.azureStaticSiteLocation
				name:              parameters.appName
				repositoryUrl:     ""
				sku: {
					name: "Free"
					tier: "Free"
				}
				provider: "SwaCli"
			}
		}
		"\(_cnameRecord)": azure.#AzureDnsRecordSet & {
			options: _azureProvider
			properties: {
				resourceGroupName: parameters.azureDnsZoneResourceGroupName
				recordType:        "CNAME"
				cnameRecord: cname: "${\(_staticSite).defaultHostname}"
				zoneName:              parameters.azureDnsZoneName
				relativeRecordSetName: parameters.relativeRecordSetName
				ttl:                   strconv.Atoi(parameters.azureCnameRecordTtl)
			}
		}
		"\(_waitCnamePropagation)": base.#Resource & {
			type: "time:Sleep"
			options: {
				dependsOn: ["${\(_cnameRecord)}"]
			}
			properties: {
				createDuration: "2m"
			}
		}
		"\(_staticSiteCustomDomain)": azure.#AzureStaticSiteCustomDomain & {
			options: {
				_azureProvider
				dependsOn: ["${\(_waitCnamePropagation)}"]
			}
			properties: {
				resourceGroupName: parameters.azureResourceGroupName
				domainName: {
					"fn::invoke": {
						function: "str:trimSuffix"
						arguments: {
							string: "${\(_cnameRecord).fqdn}"
							suffix: "."
						}
						return: "result"
					}
				}
				name: "${\(_staticSite).name}"
			}
		}
	}
}
