package azurePublicIpAddress

import (
	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName: string
	}

	_azureProvider: provider: "${AzureProvider}"

	_pubicIpAddress: azure.#AzurePublicIPAddress & {
		options: _azureProvider
		properties: {
			resourceGroupName:        "${resourceGroup.name}"
			location:                 "japaneast"
			publicIPAddressVersion:   "IPv4"
			publicIPAllocationMethod: "Static"
			sku: "name": "Standard"
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
