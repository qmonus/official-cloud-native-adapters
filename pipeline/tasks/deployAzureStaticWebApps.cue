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
		appName: desc:                "Application Name of QmonusVS"
		azureTenantId: desc:          "Azure Tenant ID"
		azureSubscriptionId: desc:    "Azure Subscription ID"
		azureResourceGroupName: desc: "Azure Resource Group"
		azureApplicationId: desc:     "Azure Application ID"
		azureClientSecretName: desc:  "Credential Name of Azure Client Secret"
		deployTargetDir: {
			desc:    "The path to the frontend build working directory"
			default: "dist"
		}
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		image:      "swacli/static-web-apps-cli:1.1.6"
		name:       "deploy"
		workingDir: "$(workspaces.shared.path)/source"
		script: """
			#!/usr/bin/env bash
			az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} --output none
			secret=$(az staticwebapp secrets list --name ${SWA_CLI_APP_NAME} --resource-group ${AZURE_RESOURCE_GROUP} --query "properties.apiKey" | tr -d '"')
			if [ -n "${secret}" ]; then
			  swa deploy $(params.deployTargetDir) --no-use-keychain --deployment-token ${secret}
			else
			  echo "SKIP: secret of azure static web app not found"
			fi
			"""
		env: [{
			name:  "AZURE_TENANT_ID"
			value: "$(params.azureTenantId)"
		}, {
			name:  "AZURE_SUBSCRIPTION_ID"
			value: "$(params.azureSubscriptionId)"
		}, {
			name:  "AZURE_RESOURCE_GROUP"
			value: "$(params.azureResourceGroupName)"
		}, {
			name:  "SWA_CLI_APP_NAME"
			value: "$(params.appName)"
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
