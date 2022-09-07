package kustomization

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#Builder: schema.#TaskBuilder
#Builder: {
	name: "kustomization"

	params: {
		replaceTargetImageName: {
			desc:    "Image Name to be replaced by given one. If not provided, image replacement would be skipped."
			default: ""
		}
		imageName: {
			desc:    "New Image Name to replace replaceTargetImageName using `kustomize edit set image` command. If not provided, image replacement would be skipped."
			default: ""
		}
		pathToSource: {
			desc:    "A Path to a code repository root from `shared/source` directory."
			default: ""
		}
		pathToKustomizationRoot: desc: "A Path to a directory containing kustomization.yaml which is a starting point of kustomization from code repository root."
		outputFileName: {
			desc:    "A Path and File Name from `shared` directory to dump kustomization result."
			default: "manifests/output.yaml"
		}
	}

	steps: [{
		image: "line/kubectl-kustomize@sha256:23bf24e557875f061e9230d3ff92fd50a3eb220ff1175772b05f8e70e4657813"
		name:  "kustomization"
		script: """
			#!/usr/bin/env sh
			set -o nounset
			set -o xtrace

			cd $(workspaces.shared.path)/source/$(params.pathToSource)

			if [ -n "$(params.replaceTargetImageName)" ] && [ -n "$(params.imageName)" ]; then
			    (cd $(params.pathToKustomizationRoot) && kustomize edit set image $(params.replaceTargetImageName)=$(params.imageName))
			fi
			mkdir -p `dirname $(workspaces.shared.path)/$(params.outputFileName)`
			kustomize build $(params.pathToKustomizationRoot) > $(workspaces.shared.path)/$(params.outputFileName)
			echo $(workspaces.shared.path)/$(params.outputFileName)

			"""

		workingDir: "$(workspaces.shared.path)"
	}]
	workspaces: [{
		name: "shared"
	}]
}
