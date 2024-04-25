package getUrlOfAzureAppService

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "get-url-azure-app-service"
	input: #BuildInput

	results: {
		defaultDomain: {
			description: "app service default domain url"
		}
		customDomain: {
			description: "app service custom domain url"
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
		image:      "mcr.microsoft.com/azure-cli:2.51.0"
		workingDir: "$(workspaces.shared.path)/source"
		script: """
			az login --service-principal -u "${AZURE_CLIENT_ID}" -p "${AZURE_CLIENT_SECRET}" --tenant "${AZURE_TENANT_ID}"
			# get url of custom domain url.  "|| true" is forced exit code 0 when deleting a resource because it has no target and exits. ( az target resource is not found )
			results=$(az webapp config hostname list --webapp-name "qvs-$(params.appName)-web-app" --resource-group "$(params.azureResourceGroupName)" --query "[].name" -o tsv 2> /dev/null || true)
			if [ -z "${results}" ]; then
				echo ""  | tee /tekton/results/defaultDomain
				echo ""  | tee /tekton/results/customDomain
			else
				domainIndex=1
				scheme='https://'
				printf '%s\n' "$results" | while IFS= read -r domain; do
					if [ $domainIndex -eq 1 ]; then
						echo "${scheme}${domain}" | tee /tekton/results/defaultDomain
					else
						echo "${scheme}${domain}" | tee /tekton/results/customDomain
					fi
					domainIndex=$((domainIndex + 1))
				done
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
