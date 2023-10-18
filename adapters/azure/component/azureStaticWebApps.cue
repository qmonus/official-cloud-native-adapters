package azureStaticWebApps

import (
	"strconv"

	"qmonus.net/adapter/official/pulumi/base/azure"
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

	_azureProvider: "${\(azure.default.provider)}"

	let _staticSite = "staticSite"
	let _cnameRecord = "cnameRecord"
	let _staticSiteCustomDomain = "staticSiteCustomDomain"

	resources: app: {
		"\(_staticSite)": azure.#Resource & {
			type: "azure-native:web:StaticSite"
			options: provider: _azureProvider
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
		"\(_cnameRecord)": azure.#Resource & {
			type: "azure-native:network:RecordSet"
			options: provider: _azureProvider
			properties: {
				resourceGroupName: parameters.azureDnsZoneResourceGroupName
				recordType:        "CNAME"
				cnameRecord: cname: "${\(_staticSite).defaultHostname}"
				zoneName:              parameters.azureDnsZoneName
				relativeRecordSetName: parameters.relativeRecordSetName
				ttl:                   strconv.Atoi(parameters.azureCnameRecordTtl)
				metadata: "managed-by": "Qmonus Value Stream"
			}
		}
		"\(_staticSiteCustomDomain)": azure.#Resource & {
			type: "azure-native:web:StaticSiteCustomDomain"
			options: provider: _azureProvider
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
