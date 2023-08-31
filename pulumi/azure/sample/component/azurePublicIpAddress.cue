package azurePublicIpAddress

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureBastionPublicIpAddress"

	parameters: {
		appName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	_pubicIpAddress: azure.#Resource & {
		options: _azureProvider
		type:    "azure-native:network:PublicIPAddress"
		properties: {
			resourceGroupName:        "${resourceGroup.name}"
			location:                 "japaneast"
			publicIPAddressVersion:   "IPv4"
			publicIPAllocationMethod: "Static"
			sku: "name":        "Standard"
			tags: "managed-by": "Qmonus Value Stream"
			zones: ["1"]
		}
	}

	resources: app: {
		// public ip address for application gateway
		applicationGatewayPublicIpAddress: _pubicIpAddress & {
			properties: {
				publicIpAddressName: "qvs-\(parameters.appName)-application-gateway-ip"
			}
		}
	}
}
