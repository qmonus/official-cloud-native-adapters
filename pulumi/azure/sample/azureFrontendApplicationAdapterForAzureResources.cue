package azureFrontendApplicationAdapterForAzureResources

import (
	"strconv"

	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "azure:azureFrontendApplicationAdapterForAzureResources"

	parameters: {
		appName:                 string
		azureProvider:           string | *"\(azure.default.provider)"
		azureStaticSiteLocation: string
		azureSubscriptionId:     string
		azureResourceGroupName:  string
		azureDnsZoneName:        string
		azureCnameRecordTtl:     string | *"3600"
	}

	group:   string
	_prefix: string | *""
	if group != _|_ {
		_prefix: "\(group)/"
	}
	let _suffix = parameters.appName

	let _staticSite = "\(_prefix)staticSite/\(_suffix)"
	let _cnameRecord = "\(_prefix)cnameRecord/\(_suffix)"
	let _staticSiteCustomDomain = "\(_prefix)staticSiteCustomDomain/\(_suffix)"

	resources: app: {
		"\(_staticSite)": azure.#Resource & {
			type: "azure-native:web:StaticSite"
			options: provider: "${\(parameters.azureProvider)}"
			properties: {
				resourceGroupName: parameters.azureResourceGroupName
				location:          parameters.azureStaticSiteLocation
				name:              parameters.appName
				repositoryUrl:     ""
				sku: {
					name: "Free"
					tier: "Free"
				}
			}
		}
		"\(_cnameRecord)": azure.#Resource & {
			type: "azure-native:network:RecordSet"
			options: provider: "${\(parameters.azureProvider)}"
			properties: {
				resourceGroupName: parameters.azureResourceGroupName
				recordType:        "CNAME"
				cnameRecord: cname: "${\(_staticSite).defaultHostname}"
				zoneName:              parameters.azureDnsZoneName
				relativeRecordSetName: "www"
				ttl:                   strconv.Atoi(parameters.azureCnameRecordTtl)
				metadata: "managed-by": "Qmonus Value Stream"
			}
		}
		"\(_staticSiteCustomDomain)": azure.#Resource & {
			type: "azure-native:web:StaticSiteCustomDomain"
			options: provider: "${\(parameters.azureProvider)}"
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
