package promoteRollout

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "promote-rollout"
	input: #BuildInput

	params: {
		appName: desc:              "Application Name of QmonusVS"
		k8sNamespace: desc:         "The kubernetes namespace of a deploy resource target"
		kubeconfigSecretName: desc: "The secret name of Kubeconfig"
	}
	workspaces: [{
		name: "shared"
	}]
	steps: [{
		name:  "promote"
		image: "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/kubectl:2023.08.02"
		command: [
			"kubectl",
		]
		args: [
			"argo",
			"rollouts",
			"promote",
			"$(params.appName)",
			"-n",
			"$(params.k8sNamespace)",
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
