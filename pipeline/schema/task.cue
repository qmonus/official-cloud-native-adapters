package schema

import (
	corev1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/selection"
	tekton "github.com/tektoncd/pipeline/pkg/apis/pipeline/v1beta1"
)

// TBD
// task interface to pipeline
// task builder impl and methods to designPattern

// task base impl for extend
#TaskBase: tekton.#Task & {
	apiVersion: "tekton.dev/v1beta1"
	kind:       "Task"
}

#TaskBuilder: {
	// Tekton Param Definition
	#TaskParam: {
		desc:    string
		default: string
		// Even if prefixAllParams is false,
		// if this flag is true,
		// add a prefix to the parameter
		prefix: bool | *false
	}

	// Tekton Result Definition
	#TaskResult: {
		description: string | *""
	}

	// When the follow definition is made in DesignPattern,
	// id will be equal to "kaniko"
	// e.g.
	// pipelines: {
	//  tasks: kaniko: kaniko.#Builder
	// }
	id: string

	// name is Task name, but NamespacedName is actually used when generating Tekton Task
	name: string

	prefix: string | *""

	// If flag is true, add prefix to parameter name
	// e.g.
	// prefix == app, param == buildTag => parameter == appBuildTag
	prefixAllParams: bool | *false

	// This parameter is currently the same as Tekton's runAfter
	// dependency between tasks
	runAfter: [...string]

	// This parameter is the same as Tekton's when expressions
	when: [...{
		input:    string | #TaskParam | #TaskResult
		operator: selection.#Operator
		values: [...string]
	}]

	// Insert approval Task when this parameter is true
	// e.g.
	// tasks: {
	//  "hoge": hoge.#Builder & {
	//   approvalRequired: true
	//  }
	// }
	//
	// The above definition is equal to the following definition
	// tasks: {
	//  "hoge": hoge.#Builder
	//  "approval-hoge": approval.#Builder & {
	//   runAfter: ["hoge"]
	//  }
	// }
	approvalRequired: bool | *false

	// injected from Pipeline Generator
	appconfigParams: [...string]
	namespace: string | *""

	// enable this flag if the task requires application secrets
	useAppSecrets: bool | *false

	// input given by user
	input: {
		// constant parameters passed from pipeline.
		// constParams is Map, but the value is string or #TaskResult.
		// The tekton parameter format string is not allowed in the value.
		constParams: {[string]: !~"\\$\\(params\\..*\\)" | #TaskResult}

		// When env is specified, Task is executed only in the environment
		// If env is empty, Task is executed in all environments.
		env: string | *""
		...
	}

	// Tekton Task params, steps, volumes, workspaces, results
	params: [string]: #TaskParam
	steps: [...tekton.#Step]
	volumes: [...corev1.#Volume]
	workspaces: [...tekton.#WorkspaceDeclaration]
	results: [string]: #TaskResult
	sidecars: [...tekton.#Sidecar]
}
