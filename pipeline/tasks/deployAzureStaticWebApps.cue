package deployAzureStaticWebApps

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "deploy-azure-static-web-apps"
	input: #BuildInput

	params: {
		azureTenantId: desc:         "Azure Tenant ID"
		azureSubscriptionId: desc:   "Azure Subscription ID"
		azureApplicationId: desc:    "Azure Application ID"
		azureClientSecretName: desc: "Credential Name of Azure Client Secret"
		azureStaticSiteName: desc:   "Azure Static Web App application name"
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		image: "swacli/static-web-apps-cli:1.1.4"
		name:  "deploy"
		command: ["swa"]
		args: ["deploy", "./dist/", "--no-use-keychain"]
		workingDir: "$(workspaces.shared.path)/source"
		env: [{
			name:  "AZURE_TENANT_ID"
			value: "$(params.azureTenantId)"
		}, {
			name:  "AZURE_SUBSCRIPTION_ID"
			value: "$(params.azureSubscriptionId)"
		}, {
			name:  "SWA_CLI_APP_NAME"
			value: "$(params.azureStaticSiteName)"
		}, {
			name:  "SWA_CLI_DEPLOY_ENV"
			value: "production"
		}, {
			name:  "AZURE_CLIENT_ID"
			value: "$(params.azureApplicationId)"
		}, {
			name: "AZURE_CLIENT_SECRET"
			valueFrom: secretKeyRef: {
				name: "$(params.azureClientSecretName)"
				key:  "password"
			}
		}]
		securityContext: runAsUser: 0
	}]
}
