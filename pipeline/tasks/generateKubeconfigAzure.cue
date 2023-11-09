package generateKubeconfigAzure

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "generate-kubeconfig"

	input: #BuildInput

	let _stack = "$(params.appName)-$(params.qvsDeploymentName)-$(params.deployStateName)"

	params: {
		appName: desc:                "Application Name of QmonusVS"
		azureTenantId: desc:          "Azure Tenant ID"
		azureSubscriptionId: desc:    "Azure Subscription ID"
		azureApplicationId: desc:     "Azure Application ID"
		azureClientSecretName: desc:  "Credential Name of Azure Client Secret"
		azureResourceGroupName: desc: "Resource Group Name of Azure Resources"
		qvsDeploymentName: desc:      "Deployment Name of QmonusVS"
		deployStateName: {
			desc: "Used as pulumi-stack name suffix"
		}
		appK8sNamespaces: {
			desc:    "Comma separated list of namespaces in which kubeconfig will be generated"
			default: ""
		}
	}
	steps: [{
		image:      "python"
		name:       "parse-azure-secret-name"
		script:     """
			#!/usr/bin/env python3
			import json
			import sys
			with open("/tmp/vault-name", mode="w") as vn:
				vn.write('')
			f = open('./.pulumi/stacks/local/\(_stack).json', 'r')
			json_object = json.load(f)
			for resource in json_object["checkpoint"]["latest"]["resources"]:
				if (resource["type"] == "azure-native:keyvault:Secret") and (resource["outputs"]["name"] == "kubeconfig"):
					with open("/tmp/vault-name", mode="w") as vn:
						vn.write(resource["inputs"]["vaultName"])
			"""
		workingDir: "$(workspaces.shared.path)/pulumi/\(_stack)"
		volumeMounts: [{
			name:      "tmp"
			mountPath: "/tmp"
		}]
	}, {
		image: "mcr.microsoft.com/azure-cli"
		name:  "download-kubeconfig"
		script: """
			#!/bin/sh
			set -o nounset
			set -o xtrace
			set -o pipefail
			set -e +x

			if [ ! -e /tmp/vault-name ]; then
			  echo "cannot read Azure Key Vault Name from state"
			  exit 1
			fi
			VAULT_NAME=`cat /tmp/vault-name`
			if [ -z $VAULT_NAME ]; then
			  echo "SKIP: azure key container not found"
			  exit 0
			fi

			az login --service-principal -u $(params.azureApplicationId) -p $AZURE_CLIENT_SECRET --tenant $(params.azureTenantId) > /dev/null
			az keyvault secret show --name kubeconfig --vault-name $VAULT_NAME --subscription $(params.azureSubscriptionId) --query value -o tsv > /tmp/kubeconfig-admin
			set -x
			"""
		env: [{
			name: "AZURE_CLIENT_SECRET"
			valueFrom: secretKeyRef: {
				name: "$(params.azureClientSecretName)"
				key:  "password"
			}
		}]
		volumeMounts: [{
			name:      "tmp"
			mountPath: "/tmp"
		}]
	}, {
		image: "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/qvsctl:v0.12.0-rc.1"
		name:  "gen-kubeconfig"
		script: """
			set -e

			if [ ! -e /tmp/vault-name ]; then
			  echo "cannot read Azure Key Vault Name from state"
			  exit 1
			fi
			VAULT_NAME=`cat /tmp/vault-name`
			if [ -z $VAULT_NAME ]; then
			  echo "SKIP: azure key container not found"
			  exit 0
			fi

			appK8sNamespaces="$(params.appK8sNamespaces)"
			for ns in $(echo -n "$appK8sNamespaces" | tr "," "\n")
			do
				/src/qvsctl plugin gen-kubeconfig -n ${ns} -o /tmp/output.kubeconfig-${ns}.yaml -y
				echo ""
			done
			"""
		env: [{
			name:  "KUBECONFIG"
			value: "/tmp/kubeconfig-admin"
		}, {
			name:  "QVSCTL_SKIP_UPDATE_CHECK"
			value: "true"
		}]
		volumeMounts: [{
			name:      "tmp"
			mountPath: "/tmp"
		}]
	}, {
		image: "mcr.microsoft.com/azure-cli"
		name:  "save-namespaced-kubeconfig"
		script: """
			#!/bin/sh
			set -o nounset
			set -o xtrace
			set -o pipefail
			set -e +x

			if [ ! -e /tmp/vault-name ]; then
			  echo "cannot read Azure Key Vault Name from state"
			  exit 1
			fi
			VAULT_NAME=`cat /tmp/vault-name`
			if [ -z $VAULT_NAME ]; then
			  echo "SKIP: azure key container not found"
			  exit 0
			fi

			appK8sNamespaces="$(params.appK8sNamespaces)"
			for ns in $(echo -n "$appK8sNamespaces" | tr "," "\n")
			do
				az login --service-principal -u $(params.azureApplicationId) -p $AZURE_CLIENT_SECRET --tenant $(params.azureTenantId) > /dev/null
				az keyvault secret set --name kubeconfig-${ns} --vault-name $VAULT_NAME --file /tmp/output.kubeconfig-${ns}.yaml --only-show-errors --output none
			done
			set -x
			"""
		env: [{
			name: "AZURE_CLIENT_SECRET"
			valueFrom: secretKeyRef: {
				name: "$(params.azureClientSecretName)"
				key:  "password"
			}
		}, {
			name:  "KUBECONFIG"
			value: "/tmp/kubeconfig-admin"
		}]
		volumeMounts: [{
			name:      "tmp"
			mountPath: "/tmp"
		}]
	}]
	workspaces: [{
		name: "shared"
	}]
	volumes: [{
		name: "tmp"
		emptyDir: {}
	}]
}
