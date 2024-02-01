package deployByPulumiYaml

import (
	"list"
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	phase:                "app" | *""
	pulumiCredentialName: string | *"qmonus-pulumi-secret"
	useCred: {
		kubernetes: bool | *false
		gcp:        bool | *false
		aws:        bool | *false
		azure:      bool | *false
	}
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "deploy-by-pulumi-yaml"

	input:  #BuildInput
	prefix: input.phase

	let _input = input
	let _configPath = "$(workspaces.shared.path)/manifests/pulumi/"
	let _pulumiStackSuffixDefault = {
		if _input.phase == "" {
			"main"
		}
		if _input.phase != "" {
			_input.phase
		}
	}

	let _stack = "$(params.appName)-$(params.qvsDeploymentName)-$(params.deployStateName)"
	let _workingDir = "$(workspaces.shared.path)/pulumi/\(_stack)"
	let _previewListFileName = "preview_list.txt"
	let _resourcesBeforeDeployFileName = "resources_before_deploy.txt"

	params: {
		appName: desc:           "Application Name of QmonusVS"
		qvsDeploymentName: desc: "Deployment Name of QmonusVS"
		deployStateName: {
			desc:    "Used as pulumi-stack name suffix"
			default: _pulumiStackSuffixDefault
		}
		if _input.useCred.kubernetes {
			kubeconfigSecretName: desc: "The secret name of Kubeconfig"
		}
		if _input.useCred.gcp {
			gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential"
		}
		if _input.useCred.aws {
			awsCredentialName: desc: "The secret name of AWS credential"
		}
		if _input.useCred.azure {
			azureApplicationId: desc:    "Azure Application ID"
			azureTenantId: desc:         "Azure Tenant ID"
			azureSubscriptionId: desc:   "Azure Subscription ID"
			azureClientSecretName: desc: "Credential Name of Azure Client Secret"
		}
		if _input.useBastionSshCred {
			bastionSshHost: desc:                   "Bastion SSH host name or ip address"
			bastionSshUserName: desc:               "Bastion SSH user name"
			bastionSshKeySecretName: desc:          "Bastion SSH private key secret name"
			sshPortForwardingDestinationHost: desc: "Port forwarding destination host name or IP address"
			sshPortForwardingDestinationPort: desc: "Port forwarding destination port"
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
		name:   "display-deploy-resources-overview"
		image:  "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/pulumi-patched:\(base.config.pulumiPatchedImageTag)"
		script: """
		#!/usr/bin/env bash
		if [ -e \(_previewListFileName) ]; then
			rm \(_previewListFileName)
		fi
		if [ -n "${GOOGLE_CREDENTIALS}" ]; then gcloud auth activate-service-account --key-file=${GOOGLE_CREDENTIALS}; fi
		pulumi login ${PULUMI_BACKEND_URL} &> /dev/null
		pulumi stack select --create \(_stack)  &> /dev/null
		PULUMI_PREVIEW=`pulumi preview -r --stack \(_stack) -j --show-sames`
		PULUMI_PREVIEW_ERROR=`[[ $? != 0 ]] && echo true || echo false`
		echo $PULUMI_PREVIEW | jq -c '.steps[] | {action:.op, urn:.urn}' > tmp_preview_list.txt
		if [ ! -s "tmp_preview_list.txt" ]; then
		  echo 'error: invalid Pulumi.yaml.'
		  echo 'error: faild to run "pulumi preview".'
		  exit 1
		fi
		DIAGNOSTICS=`echo $PULUMI_PREVIEW | jq -c '.diagnostics // empty'`
		if "$PULUMI_PREVIEW_ERROR"; then
		  echo "error: faild to run "pulumi preview"."
		  echo -e '\\nDiagnostics:'
		  echo $DIAGNOSTICS | jq -cr '.[] | .message'
		  exit 1
		fi
		while read -r PREVIEW; do
		  URN=$(echo "${PREVIEW}" | jq -r '.urn')
		  if grep -q "pulumi:pulumi:Stack" <<< "$URN"; then
		    continue
		  fi
		  ACTION=$(echo "${PREVIEW}" | jq -r '.action')
		  if [ "$ACTION" = "same" ]; then ACTION="unchanged"; fi
		  SPLIT_URN=(${URN//::/ })
		  echo ${SPLIT_URN[2]} ${SPLIT_URN[3]} ${ACTION}
		  echo "$PREVIEW" >> \(_previewListFileName)
		done < tmp_preview_list.txt
		if [ ! -s "\(_previewListFileName)" ]; then echo "no resources."; fi
		pulumi stack export 2> /dev/null | jq -c '.deployment.resources[]?' > \(_resourcesBeforeDeployFileName)
		if [ -n "$DIAGNOSTICS" ]; then
		  echo -e '\\nDiagnostics:'
		  echo $DIAGNOSTICS | jq -cr '.[] | .message'
		fi
		"""
		env:    list.FlattenN([
			{
				name:  "PULUMI_BACKEND_URL"
				value: "file://\(_workingDir)"
			},
			{
				name: "PULUMI_CONFIG_PASSPHRASE"
				valueFrom: secretKeyRef: {
					name: _input.pulumiCredentialName
					key:  "passphrase"
				}
			},
			if _input.useCred.kubernetes {
				name:  "KUBECONFIG"
				value: "/secret/kubernetes/kubeconfig"
			},
			if _input.useCred.gcp {
				name:  "GOOGLE_CREDENTIALS"
				value: "/secret/gcp/account.json"
			},
			if _input.useCred.aws {
				name:  "AWS_SHARED_CREDENTIALS_FILE"
				value: "/secret/aws/credentials"
			},
			if _input.useCred.azure {
				[
					{
						name:  "ARM_CLIENT_ID"
						value: "$(params.azureApplicationId)"
					},
					{
						name:  "ARM_TENANT_ID"
						value: "$(params.azureTenantId)"
					},
					{
						name:  "ARM_SUBSCRIPTION_ID"
						value: "$(params.azureSubscriptionId)"
					},
					{
						name: "ARM_CLIENT_SECRET"
						valueFrom: secretKeyRef: {
							name: "$(params.azureClientSecretName)"
							key:  "password"
						}
					},
				]
			},
		], -1)
		volumeMounts: [
			if _input.useCred.kubernetes {
				{
					mountPath: "/secret/kubernetes"
					name:      "user-kubeconfig"
					readOnly:  true
				}
			},
			if _input.useCred.gcp {
				{
					mountPath: "/secret/gcp"
					name:      "gcp-secret"
					readOnly:  true
				}
			},
			if _input.useCred.aws {
				{
					mountPath: "/secret/aws"
					name:      "aws-secret"
					readOnly:  true
				}
			},
		]
		resources: {
			requests: {
				cpu:    "1"
				memory: "2Gi"
			}
			limits: {
				cpu:    "1"
				memory: "2Gi"
			}
		}
		workingDir: "\(_configPath)"
	}, {
		name:    "deploy"
		image:   "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/pulumi-patched:\(base.config.pulumiPatchedImageTag)"
		onError: "continue"
		script:  """
		#!/usr/bin/env bash
		set -o nounset
		set -o xtrace
		if [ -n "${GOOGLE_CREDENTIALS:-}" ]; then gcloud auth activate-service-account --key-file=${GOOGLE_CREDENTIALS}; fi
		pulumi login ${PULUMI_BACKEND_URL}
		pulumi stack select --create \(_stack)
		pulumi up -y -r --stack \(_stack)
		"""
		env:     list.FlattenN([
				{
				name:  "PULUMI_BACKEND_URL"
				value: "file://\(_workingDir)"
			},
			{
				name: "PULUMI_CONFIG_PASSPHRASE"
				valueFrom: secretKeyRef: {
					name: _input.pulumiCredentialName
					key:  "passphrase"
				}
			},
			if _input.useCred.kubernetes {
				name:  "KUBECONFIG"
				value: "/secret/kubernetes/kubeconfig"
			},
			if _input.useCred.gcp {
				name:  "GOOGLE_CREDENTIALS"
				value: "/secret/gcp/account.json"
			},
			if _input.useCred.aws {
				name:  "AWS_SHARED_CREDENTIALS_FILE"
				value: "/secret/aws/credentials"
			},
			if _input.useCred.azure {
				[
					{
						name:  "ARM_CLIENT_ID"
						value: "$(params.azureApplicationId)"
					},
					{
						name:  "ARM_TENANT_ID"
						value: "$(params.azureTenantId)"
					},
					{
						name:  "ARM_SUBSCRIPTION_ID"
						value: "$(params.azureSubscriptionId)"
					},
					{
						name: "ARM_CLIENT_SECRET"
						valueFrom: secretKeyRef: {
							name: "$(params.azureClientSecretName)"
							key:  "password"
						}
					},
				]
			},
		], -1)
		resources: {
			requests: {
				cpu:    "1"
				memory: "2Gi"
			}
			limits: {
				cpu:    "1"
				memory: "2Gi"
			}
		}
		volumeMounts: [
			if _input.useCred.kubernetes {
				{
					mountPath: "/secret/kubernetes"
					name:      "user-kubeconfig"
					readOnly:  true
				}
			},
			if _input.useCred.gcp {
				{
					mountPath: "/secret/gcp"
					name:      "gcp-secret"
					readOnly:  true
				}
			},
			if _input.useCred.aws {
				{
					mountPath: "/secret/aws"
					name:      "aws-secret"
					readOnly:  true
				}
			},
		]
		workingDir: "\(_configPath)"
	}, {
		name:    "display-deploy-result-overview"
		image:   "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/pulumi-patched:\(base.config.pulumiPatchedImageTag)"
		onError: "continue"
		script:  """
		#!/usr/bin/env bash
		if [ ! -s "\(_previewListFileName)" ]; then
		  echo 'no difference.'
		  exit 0
		fi
		pulumi login ${PULUMI_BACKEND_URL} &> /dev/null
		pulumi stack select \(_stack)  &> /dev/null
		pulumi stack export 2> /dev/null | jq -c '.deployment.resources[]' > resources_after_deploy.txt
		RESOURCES_BEFORE_DEPLOY=`cat \(_resourcesBeforeDeployFileName)`
		RESOURCES_AFTER_DEPLOY=`cat resources_after_deploy.txt`
		while read -r PREVIEW; do
		  ACTION=$(echo "${PREVIEW}" | jq -r '.action')
		  URN=$(echo "${PREVIEW}" | jq -r '.urn')
		  RESULT="failed"
		  case "$ACTION" in
		    create)
		      AFTER_DEPLOY=`echo $RESOURCES_AFTER_DEPLOY | jq -r "select(.urn == \\"$URN\\")"`
		      if [ -n "$AFTER_DEPLOY" ]; then RESULT="created"; fi ;;
		    update)
		      BEFORE_UPDATE=`echo $RESOURCES_BEFORE_DEPLOY | jq -r "select(.urn == \\"$URN\\") | .modified"`
		      AFTER_UPDATE=`echo $RESOURCES_AFTER_DEPLOY | jq -r "select(.urn == \\"$URN\\") | .modified"`
		      if [ "$BEFORE_UPDATE" != "$AFTER_UPDATE" ]; then RESULT="updated"; fi ;;
		    replace)
		      BEFORE_REPLACE=`echo $RESOURCES_BEFORE_DEPLOY | jq -r "select(.urn == \\"$URN\\") | .created"`
		      AFTER_REPLACE=`echo $RESOURCES_AFTER_DEPLOY | jq -r "select(.urn == \\"$URN\\") | .created"`
		      if [ "$BEFORE_REPLACE" != "$AFTER_REPLACE" ]; then RESULT="replaced"; fi ;;
		    delete)
		      AFTER_DEPLOY=`echo $RESOURCES_AFTER_DEPLOY | jq -r "select(.urn == \\"$URN\\")"`
		      if [ -z "$AFTER_DEPLOY" ]; then RESULT="deleted"; fi ;;
		    same)
		      RESULT="unchanged"
		  esac
		  SPLIT_URN=(${URN//::/ })
		  echo ${SPLIT_URN[2]} ${SPLIT_URN[3]} ${RESULT}
		done < \(_previewListFileName)
		"""
		env: [
			{
				name:  "PULUMI_BACKEND_URL"
				value: "file://\(_workingDir)"
			},
			{
				name: "PULUMI_CONFIG_PASSPHRASE"
				valueFrom: secretKeyRef: {
					name: _input.pulumiCredentialName
					key:  "passphrase"
				}
			},
		]
		workingDir: "\(_configPath)"
	}, {
		name:   "upload-state"
		image:  "google/cloud-sdk:365.0.1-slim@sha256:2575543b18e06671eac29aae28741128acfd0e4376257f3f1246d97d00059dcb"
		script: """
			#!/usr/bin/env bash
			set -o nounset
			set -o xtrace
			set -o pipefail

			cd '\(_workingDir)'
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
	if _input.useBastionSshCred {
		sidecars: [{
			name:  "ssh-port-forwarding"
			image: "linuxserver/openssh-server"
			command: ["ssh"]
			args: [ "-4",
				"-NL", "$(params.sshPortForwardingDestinationPort):$(params.sshPortForwardingDestinationHost):$(params.sshPortForwardingDestinationPort)", "$(params.bastionSshUserName)@$(params.bastionSshHost)",
				"-i", "/root/.ssh/id_rsa",
				"-o", "StrictHostKeyChecking=no",
				"-o", "UserKnownHostsFile=/dev/null",
			]
			volumeMounts: [{
				name:      "bastion-ssh-key"
				mountPath: "/root/.ssh"
			}]
		}]
	}
	volumes: [
		if _input.useCred.kubernetes {
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
		if _input.useCred.gcp {
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
		if _input.useCred.aws {
			{
				name: "aws-secret"
				secret: {
					items: [{
						key:  "credentials"
						path: "credentials"
					}]
					secretName: "$(params.awsCredentialName)"
				}
			}
		},
		if _input.useBastionSshCred {
			{
				name: "bastion-ssh-key"
				secret: {
					items: [{
						key:  "identity_file"
						path: "id_rsa"
					}]
					secretName:  "$(params.bastionSshKeySecretName)"
					defaultMode: 256
				}
			}
		},
	]
	workspaces: [{
		name: "shared"
	}]
}
