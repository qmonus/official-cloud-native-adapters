package resolveIPAddress

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "resolve-ip-address"

	params: {
		appName: desc:              "Application Name of QmonusVS"
		k8sNamespace: desc:         "Namespace of a deploy resource"
		kubeconfigSecretName: desc: "The secret name of Kubeconfig"
	}

	results: {
		ipAddress: {
			description: "External IP Address"
		}
	}

	steps: [{
		name:  "resolve-external-ip-address"
		image: "gcr.io/cloud-builders/kubectl"
		script: """
			#!/usr/bin/env sh
			kubectl -n $(params.k8sNamespace) --kubeconfig $KUBECONFIG get service $(params.appName) -o=jsonpath='{.status.loadBalancer.ingress[0].ip}' | tee tekton/results/ipAddress
			"""
		env: [
			{
				name:  "KUBECONFIG"
				value: "/secret/kubeconfig"
			}]
		volumeMounts: [
			{
				mountPath: "/secret"
				name:      "user-kubeconfig"
				readOnly:  true
			},
		]
	}]
	volumes: [
		{
			name: "user-kubeconfig"
			secret: {
				items: [{
					key:  "kubeconfig"
					path: "kubeconfig"
				}]
				secretName: "$(params.kubeconfigSecretName)"
			}
		},
	]
}
