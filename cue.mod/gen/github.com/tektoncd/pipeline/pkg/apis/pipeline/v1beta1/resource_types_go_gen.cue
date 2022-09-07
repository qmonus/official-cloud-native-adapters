// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/tektoncd/pipeline/pkg/apis/pipeline/v1beta1

package v1beta1

import (
	resource "github.com/tektoncd/pipeline/pkg/apis/resource/v1alpha1"
	"k8s.io/api/core/v1"
)

// PipelineResourceType represents the type of endpoint the pipelineResource is, so that the
// controller will know this pipelineResource should be fetched and optionally what
// additional metatdata should be provided for it.
#PipelineResourceType: string // #enumPipelineResourceType

#enumPipelineResourceType:
	#PipelineResourceTypeGit |
	#PipelineResourceTypeStorage |
	#PipelineResourceTypeImage |
	#PipelineResourceTypeCluster |
	#PipelineResourceTypePullRequest |
	#PipelineResourceTypeCloudEvent

// PipelineResourceTypeGit indicates that this source is a GitHub repo.
#PipelineResourceTypeGit: "git"

// PipelineResourceTypeStorage indicates that this source is a storage blob resource.
#PipelineResourceTypeStorage: "storage"

// PipelineResourceTypeImage indicates that this source is a docker Image.
#PipelineResourceTypeImage: "image"

// PipelineResourceTypeCluster indicates that this source is a k8s cluster Image.
#PipelineResourceTypeCluster: "cluster"

// PipelineResourceTypePullRequest indicates that this source is a SCM Pull Request.
#PipelineResourceTypePullRequest: "pullRequest"

// PipelineResourceTypeCloudEvent indicates that this source is a cloud event URI
#PipelineResourceTypeCloudEvent: "cloudEvent"

// TaskResources allows a Pipeline to declare how its DeclaredPipelineResources
// should be provided to a Task as its inputs and outputs.
#TaskResources: {
	// Inputs holds the mapping from the PipelineResources declared in
	// DeclaredPipelineResources to the input PipelineResources required by the Task.
	inputs?: [...#TaskResource] @go(Inputs,[]TaskResource)

	// Outputs holds the mapping from the PipelineResources declared in
	// DeclaredPipelineResources to the input PipelineResources required by the Task.
	outputs?: [...#TaskResource] @go(Outputs,[]TaskResource)
}

// TaskResource defines an input or output Resource declared as a requirement
// by a Task. The Name field will be used to refer to these Resources within
// the Task definition, and when provided as an Input, the Name will be the
// path to the volume mounted containing this Resource as an input (e.g.
// an input Resource named `workspace` will be mounted at `/workspace`).
#TaskResource: {
	resource.#ResourceDeclaration
}

// TaskRunResources allows a TaskRun to declare inputs and outputs TaskResourceBinding
#TaskRunResources: {
	// Inputs holds the inputs resources this task was invoked with
	inputs?: [...#TaskResourceBinding] @go(Inputs,[]TaskResourceBinding)

	// Outputs holds the inputs resources this task was invoked with
	outputs?: [...#TaskResourceBinding] @go(Outputs,[]TaskResourceBinding)
}

// TaskResourceBinding points to the PipelineResource that
// will be used for the Task input or output called Name.
#TaskResourceBinding: {
	#PipelineResourceBinding

	// Paths will probably be removed in #1284, and then PipelineResourceBinding can be used instead.
	// The optional Path field corresponds to a path on disk at which the Resource can be found
	// (used when providing the resource via mounted volume, overriding the default logic to fetch the Resource).
	// +optional
	paths?: [...string] @go(Paths,[]string)
}

// ResourceDeclaration defines an input or output PipelineResource declared as a requirement
// by another type such as a Task or Condition. The Name field will be used to refer to these
// PipelineResources within the type's definition, and when provided as an Input, the Name will be the
// path to the volume mounted containing this PipelineResource as an input (e.g.
// an input Resource named `workspace` will be mounted at `/workspace`).
#ResourceDeclaration: resource.#ResourceDeclaration

// PipelineResourceBinding connects a reference to an instance of a PipelineResource
// with a PipelineResource dependency that the Pipeline has declared
#PipelineResourceBinding: {
	// Name is the name of the PipelineResource in the Pipeline's declaration
	name?: string @go(Name)

	// ResourceRef is a reference to the instance of the actual PipelineResource
	// that should be used
	// +optional
	resourceRef?: null | #PipelineResourceRef @go(ResourceRef,*PipelineResourceRef)

	// ResourceSpec is specification of a resource that should be created and
	// consumed by the task
	// +optional
	resourceSpec?: null | resource.#PipelineResourceSpec @go(ResourceSpec,*resource.PipelineResourceSpec)
}

// PipelineResourceResult used to export the image name and digest as json
#PipelineResourceResult: {
	key:           string @go(Key)
	value:         string @go(Value)
	resourceName?: string @go(ResourceName)

	// The field ResourceRef should be deprecated and removed in the next API version.
	// See https://github.com/tektoncd/pipeline/issues/2694 for more information.
	resourceRef?: null | #PipelineResourceRef @go(ResourceRef,*PipelineResourceRef)
	type?:        #ResultType                 @go(ResultType)
}

// ResultType used to find out whether a PipelineResourceResult is from a task result or not
#ResultType: _ // #enumResultType

#enumResultType:
	#TaskRunResultType

#values_ResultType: TaskRunResultType: #TaskRunResultType

// PipelineResourceRef can be used to refer to a specific instance of a Resource
#PipelineResourceRef: {
	// Name of the referent; More info: http://kubernetes.io/docs/user-guide/identifiers#names
	name?: string @go(Name)

	// API version of the referent
	// +optional
	apiVersion?: string @go(APIVersion)
}

// PipelineResourceInterface interface to be implemented by different PipelineResource types
#PipelineResourceInterface: _

// TaskModifier is an interface to be implemented by different PipelineResources
#TaskModifier: _

// InternalTaskModifier implements TaskModifier for resources that are built-in to Tekton Pipelines.
#InternalTaskModifier: {
	StepsToPrepend: [...#Step] @go(,[]Step)
	StepsToAppend: [...#Step] @go(,[]Step)
	Volumes: [...v1.#Volume] @go(,[]v1.Volume)
}
