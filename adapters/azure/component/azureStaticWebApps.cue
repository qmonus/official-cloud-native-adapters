package azureStaticWebApps

import (
	"strconv"

	"qmonus.net/adapter/official/types:azure"
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
		"\(_staticSiteCustomDomain)": azure.#AzureStaticSiteCustomDomain & {
			options: _azureProvider
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
