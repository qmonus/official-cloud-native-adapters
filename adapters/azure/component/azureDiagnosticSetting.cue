package azureDiagnosticSetting

import (
	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName:                  string
		azureResourceGroupName:   string
		logAnalyticsWorkspaceId?: string
	}

	_azureProvider: provider: "${AzureProvider}"

	resources: app: {
		diagnosticSetting: azure.#AzureDiagnosticSetting & {
			type:    "azure-native:insights:DiagnosticSetting"
			options: _azureProvider
			properties: {
				name:        "qvs-\(parameters.appName)-diagnostics"
				resourceUri: "${webAppForContainer.id}"
				workspaceId: "\(parameters.logAnalyticsWorkspaceId)"
				logs: [{
					category: "AppServiceConsoleLogs"
					enabled:  true
				}]
			}
		}
	}
}
