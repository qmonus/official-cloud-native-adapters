package deploymentWorkerPreview

import (
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	phase:      "setup" | "app" | *""
	useGcpCred: bool | *false
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "deployment-worker-preview"

	input:  #BuildInput
	prefix: input.phase

	let _input = input
	let _configPath = {
		if _input.phase == "" {
			"$(workspaces.shared.path)/manifests"
		}
		if _input.phase != "" {
			"$(workspaces.shared.path)/manifests/manifests-\(_input.phase).yml"
		}
	}
	let _pulumiStackSuffixDefault = {
		if _input.phase == "" {
			"main"
		}
		if _input.phase != "" {
			_input.phase
		}
	}
	let _workingDir = "$(workspaces.shared.path)/pulumi/$(params.appName)-$(params.qvsDeploymentName)-$(params.deployStateNameWithPreview)"

	params: {
		appName: desc:           "Application Name of QmonusVS With Preview"
		qvsDeploymentName: desc: "Deployment Name of QmonusVS With Preview"
		deployStateNameWithPreview: {
			desc:    "Used as pulumi-stack name suffix With Preview"
			default: _pulumiStackSuffixDefault
		}
		providerTypeWithPreview: {
			desc:    "Deployment-worker provider type With Preview"
			default: "kubernetes"
		}
		if !_input.useGcpCred {
			kubeconfigSecretName: desc: "The secret name of Kubeconfig"
		}
		if _input.useGcpCred {
			gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential With Preview"
			gcpProjectId: desc:                "The Project ID of a deploy resource target"
			k8sClusterName: {
				desc:    "The kubernetes cluster name of a deploy resource target"
				default: ""
			}
		}
	}
	steps: [{
		name:   "download-state"
		image:  "google/cloud-sdk:365.0.1-slim@sha256:2575543b18e06671eac29aae28741128acfd0e4376257f3f1246d97d00059dcb"
		script: """
			#!/usr/bin/env bash
			set -o nounset
			set -o xtrace
			set -o pipefail

			mkdir -p '\(_workingDir)'
			cd '\(_workingDir)'
			if [[ -d .pulumi ]]; then
			  exit 0
			fi
			SIGNED_URL=`curl -X POST -fs ${VS_API_ENDPOINT}'/apis/v1/projects/$(context.taskRun.namespace)/applications/$(params.appName)/deployments/$(params.qvsDeploymentName)/deploy-state/$(params.deployStateNameWithPreview)/action/signed-url-to-get?taskrun_name=$(context.taskRun.name)&taskrun_uid=$(context.taskRun.uid)' | xargs`
			mkdir -p /tekton/home/pulumi/old
			STATUS=`curl -fs ${SIGNED_URL} -o /tekton/home/pulumi/old/state.tgz -w '%{http_code}\\n'`
			if [ ! -z $STATUS ] && [ $STATUS -eq 404 ]; then
			  echo "No state file is provided. Create a new state."
			  exit 0
			elif [ -z $STATUS ] || [ $STATUS -ne 200 ]; then
			  echo "Error: failed to download state file."
			  exit 1
			fi
			if [ -f /tekton/home/pulumi/old/state.tgz ]; then
			  tar xzvf /tekton/home/pulumi/old/state.tgz
			else
			  echo "Error: status_code is 200 but no state file is provided."
			  exit 1
			fi

			"""
		env: [
			{
				name: "VS_API_ENDPOINT"
				valueFrom: fieldRef: fieldPath: "metadata.annotations['\(base.config.vsApiEndpointKey)']"
			},
		]
		workingDir: "/opt"
	}, {
		name:    "deploy-preview"
		image:   "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/deployment-worker:\(base.config.qmonusDeploymentWorkerRevision)"
		onError: "continue"
		args: [
			"--design-pattern=$(params.providerTypeWithPreview)",
			if _input.useGcpCred {
				"--cluster-project=$(params.gcpProjectId)"
				"--cluster-name=$(params.k8sClusterName)"
			},
			"--solarray-env=local",
			"--namespace=$(context.taskRun.namespace)-$(params.appName)-$(params.qvsDeploymentName)",
			"--app-version=$(params.deployStateNameWithPreview)",
			"--disabled-stack-validation",
			"--local-state-path=\(_workingDir)",
			"--preview",
		]
		env: [
			if !_input.useGcpCred {
				{
					name:  "KUBECONFIG"
					value: "/secret/kubeconfig"
				}
			},
			if _input.useGcpCred {
				{
					name:  "GOOGLE_APPLICATION_CREDENTIALS"
					value: "/secret/account.json"
				}
			},
			{
				name:  "CONFIG_PATH"
				value: _configPath
			},
		]
		resources: {
			requests: {
				cpu:    "1"
				memory: "1Gi"
			}
			limits: {
				cpu:    "1"
				memory: "1Gi"
			}
		}
		volumeMounts: [
			if !_input.useGcpCred {
				{
					mountPath: "/secret"
					name:      "user-kubeconfig"
					readOnly:  true
				}
			},
			if _input.useGcpCred {
				{
					mountPath: "/secret"
					name:      "gcp-secret"
					readOnly:  true
				}
			},
		]
		workingDir: "/opt"
	}]
	volumes: [
		if !_input.useGcpCred {
			{
				name: "user-kubeconfig"
				secret: {
					items: [{
						key:  "kubeconfig"
						path: "kubeconfig"
					}]
					secretName: "$(params.kubeconfigSecretName)"
				}
			}
		},
		if _input.useGcpCred {
			{
				name: "gcp-secret"
				secret: {
					items: [{
						key:  "serviceaccount"
						path: "account.json"
					}]
					secretName: "$(params.gcpServiceAccountSecretName)"
				}
			}
		},
	]
	workspaces: [{
		name: "shared"
	}]
}
