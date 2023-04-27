package schema

import (
	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1beta1"
)

#PipelineBase: tekton.#Pipeline & {
	apiVersion: "tekton.dev/v1beta1"
	kind:       "Pipeline"
}

#PipelineResults: {
	description: string
}

#PipelineBuilder: {
	stage:        string
	env:          string
	k8sNamespace: string | *""
	appconfigSecrets: [...string]
	tasks: [string]:   #TaskBuilder
	results: [string]: #PipelineResults
}
