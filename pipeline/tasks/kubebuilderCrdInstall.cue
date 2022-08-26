package kubebuilderCrdInstall

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#Builder: schema.#TaskBuilder
#Builder: {
	name: "kubebuilder-crd-install"

	params: {
		pathToSource: {
			desc:    "A Path to a code repository root from `shared/source` directory. Root has to be kubebuilder PROJECT root and contain config dir."
			default: ""
		}
		kubeconfigSecretName: desc: "The secret name of Kubeconfig"
	}

	steps: [{
		image: "line/kubectl-kustomize@sha256:23bf24e557875f061e9230d3ff92fd50a3eb220ff1175772b05f8e70e4657813"
		name:  "kustomization"
		script: """
			#!/usr/bin/env sh
			set -o nounset
			set -o xtrace

			kustomize build config/crd | kubectl diff -f -
			kustomize build config/crd | kubectl apply -f -

			"""
		env: [
			{
				name:  "KUBECONFIG"
				value: "/secret/kubeconfig"
			},
		]
		volumeMounts: [
			{
				mountPath: "/secret"
				name:      "user-kubeconfig"
				readOnly:  true
			},
		]
		workingDir: "$(workspaces.shared.path)/source/$(params.pathToSource)"
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
	workspaces: [{
		name: "shared"
	}]
}
