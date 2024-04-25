package getIdAndNameOfLogAnalyticsWorkspace

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "get-log-analytics-workspace-info"
	input: #BuildInput

	results: {
		logAnalyticsWorkspaceId: {
			description: "Log Analytics Workspace Id"
		}
		logAnalyticsWorkspaceName: {
			description: "Log Analytics Workspace Name"
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
		name:       "get-log-analytics-workspace-info"
		image:      "mcr.microsoft.com/azure-cli:2.51.0"
		workingDir: "$(workspaces.shared.path)/source"
		script: """
			az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} > /dev/null
			# get url of workspace info
			echo "get log analytics workspace information"
			workspace_name=$(az monitor log-analytics workspace list -g $(params.azureResourceGroupName) --query "[].name" -o tsv  | grep $(params.appName) || true)
			workspace_id=$(az monitor log-analytics workspace list -g $(params.azureResourceGroupName) --query "[].id" -o tsv  | grep $(params.appName) || true)
			if [ -n "${workspace_name}" ] && [ -n "${workspace_id}" ]; then
				echo "found log analytics workspace."
				echo "workspace name is ${workspace_name}" | tee /tekton/results/logAnalyticsWorkspaceId
				echo "workspace id is ${workspace_id}" | tee /tekton/results/logAnalyticsWorkspaceName
			else
				echo "log analytics workspace not found."
				echo "" | tee /tekton/results/logAnalyticsWorkspaceId
				echo "" | tee /tekton/results/logAnalyticsWorkspaceName
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
		}]
	}]
}
