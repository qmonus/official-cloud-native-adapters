package deploymentWorker

import (
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	phase:            "setup" | "app" | *""
	useGcpCred:       bool | *false
	resourcePriority: "high" | *"medium"
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "deployment-worker"

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
	let _workingDir = "$(workspaces.shared.path)/pulumi/$(params.appName)-$(params.qvsDeploymentName)-$(params.deployStateName)"

	params: {
		appName: desc:           "Application Name of QmonusVS"
		qvsDeploymentName: desc: "Deployment Name of QmonusVS"
		deployStateName: {
			desc:    "Used as pulumi-stack name suffix"
			default: _pulumiStackSuffixDefault
		}
		providerType: {
			desc:    "Deployment-worker provider type"
			default: "kubernetes"
		}
		if !_input.useGcpCred {
			kubeconfigSecretName: desc: "The secret name of Kubeconfig"
		}
		if _input.useGcpCred {
			gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential"
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
			SIGNED_URL=`curl -X POST -fs ${VS_API_ENDPOINT}'/apis/v1/projects/$(context.taskRun.namespace)/applications/$(params.appName)/deployments/$(params.qvsDeploymentName)/deploy-state/$(params.deployStateName)/action/signed-url-to-get?taskrun_name=$(context.taskRun.name)&taskrun_uid=$(context.taskRun.uid)' | xargs`
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
		name:    "deploy"
		image:   "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/deployment-worker:\(base.config.qmonusDeploymentWorkerRevision)"
		onError: "continue"
		args: [
			"--design-pattern=$(params.providerType)",
			if _input.useGcpCred {
				"--cluster-project=$(params.gcpProjectId)"
				"--cluster-name=$(params.k8sClusterName)"
			},
			"--solarray-env=local",
			"--namespace=$(context.taskRun.namespace)-$(params.appName)-$(params.qvsDeploymentName)",
			"--app-version=$(params.deployStateName)",
			"--disabled-stack-validation",
			"--local-state-path=\(_workingDir)",
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
			if _input.resourcePriority == "medium" {
				{
					name:  "GOMEMLIMIT"
					value: "700MiB"
				}
			},
			if _input.resourcePriority == "high" {
				{
					name:  "GOMEMLIMIT"
					value: "1534MiB"
				}
			},
		]
		resources: {
			if _input.resourcePriority == "medium" {
				requests: {
					cpu:    "1"
					memory: "1Gi"
				}
				limits: {
					cpu:    "1"
					memory: "1Gi"
				}
			}
			if _input.resourcePriority == "high" {
				requests: {
					cpu:    "1"
					memory: "2Gi"
				}
				limits: {
					cpu:    "1"
					memory: "2Gi"
				}
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
	}, {
		name:   "upload-state"
		image:  "google/cloud-sdk:365.0.1-slim@sha256:2575543b18e06671eac29aae28741128acfd0e4376257f3f1246d97d00059dcb"
		script: """
			#!/usr/bin/env bash
			set -o nounset
			set -o xtrace
			set -o pipefail

			cd '\(_workingDir)'

			DEPLOYMENT_STACK_NAME=$(context.taskRun.namespace)-$(params.appName)-$(params.qvsDeploymentName)-$(params.deployStateName)

			cleanupFiles() {
			  local dir=$1
			  if [[ "$dir" == *"history"* ]]; then
			    for file_type in "checkpoint" "history"; do
			      local latest_file=$(ls -t "$dir"/"$DEPLOYMENT_STACK_NAME"*.$file_type.json 2>/dev/null | head -n 1)
			      if [ -z "$latest_file" ]; then
			        echo "No $file_type files found in $dir."
			        continue
			      fi
				  local sequence=$(basename "$latest_file" | sed -E "s/^([^-]+-)+([0-9]+)\\.$file_type\\.json$/\\2/")
				  echo "Latest $file_type file: $(basename "$latest_file")"
			      for old_file in "$dir"/"$DEPLOYMENT_STACK_NAME"*.$file_type.json; do
			        if [[ -f "$old_file" && "$old_file" != "$latest_file" ]]; then
			          echo "delete $file_type file: $(basename "$old_file")"
			          rm "$old_file"
			        fi
			      done
			      for attrs_file in "$dir"/"$DEPLOYMENT_STACK_NAME"*.$file_type.json.attrs; do
			        if [[ -f "$attrs_file" && "$attrs_file" != *"$sequence"* ]]; then
			          echo "delete $file_type attrs file: $(basename "$attrs_file")"
			          rm "$attrs_file"
			        fi
			      done
			    done
			  else
			    local latest_file=$(ls -t "$dir"/"$DEPLOYMENT_STACK_NAME"*.json 2>/dev/null | head -n 1)
				if [ -z "$latest_file" ]; then
				  echo "No files found in $dir."
				  return 1
				fi
				local sequence=$(basename "$latest_file" | sed -E "s/^([^-]+-)+([0-9]+)\\..*\\.json$/\\2/")
			    if [ -z "$sequence" ]; then
			      echo "Failed to extract sequence from file: $latest_file"
				  return 1
			    fi
			    echo "Sequence to retain: $sequence"
				for file in "$dir"/*; do
			      if [[ -f "$file" && "$file" != *"$sequence"* ]]; then
			        echo "delete $file"
			        rm "$file"
			      fi
			    done
			  fi
			  echo "Cleanup completed for $dir."
			}

			cleanupFiles ".pulumi/history/local/$DEPLOYMENT_STACK_NAME"
			cleanupFiles ".pulumi/backups/local/$DEPLOYMENT_STACK_NAME"

			mkdir -p /tekton/home/pulumi/new
			tar czvf /tekton/home/pulumi/new/state.tgz .pulumi
			for i in $(seq 1 5); do
			  SIGNED_URL=`curl -X POST -fs ${VS_API_ENDPOINT}'/apis/v1/projects/$(context.taskRun.namespace)/applications/$(params.appName)/deployments/$(params.qvsDeploymentName)/deploy-state/$(params.deployStateName)/action/signed-url-to-put?taskrun_name=$(context.taskRun.name)&taskrun_uid=$(context.taskRun.uid)' | xargs`
			  STATUS=`curl -X PUT -fs ${SIGNED_URL} --upload-file /tekton/home/pulumi/new/state.tgz -w '%{http_code}\\n'`
			  if [ ! -z $STATUS ] && [ $STATUS -eq 200 ]; then
			    break
			  fi
			  if [ $i -eq 5 ]; then
			    echo "Error: failed to upload new state file."
			    exit 1
			  fi
			  sleep 10
			done
			if [ $(cat $(steps.step-deploy.exitCode.path)) -ne 0 ]; then
			  echo "Error: new state file is uploaded, but step-deploy is failed."
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
