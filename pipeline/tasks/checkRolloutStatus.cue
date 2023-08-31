package checkRolloutStatus

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "check-rollout-status"
	input: #BuildInput

	params: {
		expectedStatus: {
			desc:    "Expected rollout resources separated by commas"
			default: "Healthy"
		}
		checkTimeoutSeconds: {
			desc:    "Number of seconds to wait for status update"
			default: "300"
			prefix:  true
		}
		appName: desc:              "Application Name of QmonusVS"
		k8sNamespace: desc:         "The kubernetes namespace of a deploy resource target"
		kubeconfigSecretName: desc: "The secret name of Kubeconfig"
	}
	workspaces: [{
		name: "shared"
	}]
	steps: [{
		name:  "check-status"
		image: "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/kubectl:2023.08.02"
		script: """
			#!/bin/bash
			set -o pipefail

			function unix_now() {
			    date +'%s'
			}

			NAMESPACE=$(params.k8sNamespace)
			ROLLOUT_NAME=$(params.appName)

			# pre-check
			CHECK=$(kubectl get rollouts ${ROLLOUT_NAME} -n ${NAMESPACE})
			if [ "$?" -ne 0 ]; then
			    echo ${CHECK}
			    exit 1
			fi

			EXPECTED_STATUS=$(params.expectedStatus)
			CHECK_TIMEOUT_SECONDS=$(params.checkTimeoutSeconds)
			LIMIT_TIME=$(($(unix_now) + ${CHECK_TIMEOUT_SECONDS}))

			while [ $(unix_now) -lt ${LIMIT_TIME} ]
			do
			    STATUS=$(kubectl argo rollouts status ${ROLLOUT_NAME} -n ${NAMESPACE} -w=false | awk '{print $1}')
			    if echo ${EXPECTED_STATUS} | grep ${STATUS} > /dev/null; then
			        echo ${STATUS}
			        exit 0
			    else
			        echo "waiting on status update..."
			        sleep 1
			    fi
			done

			echo "Error: Status watch exceeded timeout (${CHECK_TIMEOUT_SECONDS}s)"
			exit 1

			"""
		env: [{
			name:  "KUBECONFIG"
			value: "/secret/kubeconfig"
		}]
		volumeMounts: [{
			name:      "user-kubeconfig"
			mountPath: "/secret"
			readOnly:  true
		}]
	}, {
		name:  "view-status"
		image: "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/kubectl:2023.08.02"
		command: [
			"kubectl",
		]
		args: [
			"argo",
			"rollouts",
			"get",
			"rollout",
			"$(params.appName)",
			"-n",
			"$(params.k8sNamespace)",
			"-w=false",
			"--no-color",
		]
		env: [{
			name:  "KUBECONFIG"
			value: "/secret/kubeconfig"
		}]
		volumeMounts: [{
			name:      "user-kubeconfig"
			mountPath: "/secret"
			readOnly:  true
		}]
	}]
	volumes: [{
		name: "user-kubeconfig"
		secret: {
			secretName: "$(params.kubeconfigSecretName)"
			items: [{
				key:  "kubeconfig"
				path: "kubeconfig"
			}]
		}
	}]
}
