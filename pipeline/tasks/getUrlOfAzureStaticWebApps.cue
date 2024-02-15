package getUrlOfAzureStaticWebApps

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "get-url-azure-static-web-apps"
	input: #BuildInput

	results: {
		publicUrl: {
			description: "static site url"
		}
	}

	params: {
		appName: desc:                "Application Name of QmonusVS"
		azureResourceGroupName: desc: "Azure Resource Group Name"
		azureTenantId: desc:          "Azure Tenant ID"
		azureSubscriptionId: desc:    "Azure Subscription ID"
		azureApplicationId: desc:     "Azure Application ID"
		azureClientSecretName: desc:  "Credential Name of Azure Client Secret"
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		name:       "geturl"
		image:      "mcr.microsoft.com/azure-cli:2.57.0"
		workingDir: "$(workspaces.shared.path)/source"
		script: """
			#!/usr/bin/env bash
			az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} --output none
			# get url of custom domain url
			result=$(az staticwebapp hostname list --name ${SWA_CLI_APP_NAME} --resource-group ${AZURE_RESOURCE_GROUP} --query '[].domainName' -o tsv || true)
			if [ -n "${result}" ]; then
			  scheme='https://'
			  echo "${scheme}${result}" | tee /tekton/results/publicUrl
			else
			  echo "" > /tekton/results/publicUrl
			  echo "SKIP: hostname of azure static web app found"
			fi
			"""
		env: [{
			name:  "AZURE_TENANT_ID"
			value: "$(params.azureTenantId)"
		}, {
			name:  "AZURE_SUBSCRIPTION_ID"
			value: "$(params.azureSubscriptionId)"
		}, {
			name:  "AZURE_CLIENT_ID"
			value: "$(params.azureApplicationId)"
		}, {
			name: "AZURE_CLIENT_SECRET"
			valueFrom: secretKeyRef: {
				name: "$(params.azureClientSecretName)"
				key:  "password"
			}
		}, {
			name:  "AZURE_RESOURCE_GROUP"
			value: "$(params.azureResourceGroupName)"
		}, {
			name:  "SWA_CLI_APP_NAME"
			value: "$(params.appName)"
		}]
	}]
}
