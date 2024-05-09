package generateKubeconfigAzure

import (
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
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
			found = False
			resources = json_object["checkpoint"]["latest"]["resources"]
			if len(resources) == 1 and resources[0]["type"] == "pulumi:pulumi:Stack":
			  print("SKIP: resources not found")
			  sys.exit(0)
			for resource in resources:
			  if (resource["type"] == "azure-native:keyvault:Secret") and (resource["outputs"]["name"] == "kubeconfig"):
			    with open("/tmp/vault-name", mode="w") as vn:
			      vn.write(resource["inputs"]["vaultName"])
			    print("Found kubeconfig secret: " + resource["inputs"]["vaultName"])
			    found = True
			if not found:
			  print("Failed to find kubeconfig secret")
			  sys.exit(1)
			"""
		workingDir: "$(workspaces.shared.path)/pulumi/\(_stack)"
		volumeMounts: [{
			name:      "tmp"
			mountPath: "/tmp"
		}]
	}, {
		image: "mcr.microsoft.com/azure-cli"
		name:  "download-admin-kubeconfig"
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
			if az keyvault secret show --name kubeconfig --vault-name $VAULT_NAME --subscription $(params.azureSubscriptionId) --query value -o tsv > /tmp/kubeconfig-admin; then
			  echo "Successfully downloaded admin kubeconfig."
			else
			  echo "Failed to download admin kubeconfig."
			  exit 1
			fi
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
		image: "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/qvsctl:\(base.config.qmonusQvsctlRevision)"
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
			if [ -z "$appK8sNamespaces" ]; then
			  echo "appK8sNamespaces is empty. Skip generating kubeconfig."
			  exit 0
			else
			  for ns in $(echo -n "$appK8sNamespaces" | tr "," "\n")
			  do
			    if /src/qvsctl plugin gen-kubeconfig -n ${ns} -o /tmp/output.kubeconfig-${ns}.yaml -y; then
			      echo "Successfully generated kubeconfig for ${ns}."
			    else
			      echo "Failed to generate kubeconfig for ${ns}."
			    fi
			  done
			fi
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
			if [ -z "$appK8sNamespaces" ]; then
			  echo "appK8sNamespaces is empty. Skip saving kubeconfig."
			  exit 0
			else
			  for ns in $(echo -n "$appK8sNamespaces" | tr "," "\n")
			  do
			    az login --service-principal -u $(params.azureApplicationId) -p $AZURE_CLIENT_SECRET --tenant $(params.azureTenantId) > /dev/null
			    if az keyvault secret set --name kubeconfig-${ns} --vault-name $VAULT_NAME --file /tmp/output.kubeconfig-${ns}.yaml --only-show-errors --output none; then
			      echo "Successfully saved kubeconfig for ${ns}."
			    else
			      echo "Failed to save kubeconfig for ${ns}."
			    fi
			  done
			fi
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
