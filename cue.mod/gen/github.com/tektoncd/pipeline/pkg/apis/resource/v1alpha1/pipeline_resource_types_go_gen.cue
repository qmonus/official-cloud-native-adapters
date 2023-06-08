// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/tektoncd/pipeline/pkg/apis/resource/v1alpha1

package v1alpha1

import metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"

// PipelineResourceType represents the type of endpoint the pipelineResource is, so that the
// controller will know this pipelineResource shouldx be fetched and optionally what
// additional metatdata should be provided for it.
#PipelineResourceType: string // #enumPipelineResourceType

#enumPipelineResourceType:
	#PipelineResourceTypeGit |
	#PipelineResourceTypeStorage |
	#PipelineResourceTypeImage |
	#PipelineResourceTypePullRequest |
	#PipelineResourceTypeGCS

// PipelineResourceTypeGit indicates that this source is a GitHub repo.
#PipelineResourceTypeGit: "git"

// PipelineResourceTypeStorage indicates that this source is a storage blob resource.
#PipelineResourceTypeStorage: "storage"

// PipelineResourceTypeImage indicates that this source is a docker Image.
#PipelineResourceTypeImage: "image"

// PipelineResourceTypePullRequest indicates that this source is a SCM Pull Request.
#PipelineResourceTypePullRequest: "pullRequest"

// PipelineResourceTypeGCS is the subtype for the GCSResources, which is backed by a GCS blob/directory.
#PipelineResourceTypeGCS: "gcs"

// PipelineResource describes a resource that is an input to or output from a
// Task.
//
// +k8s:openapi-gen=true
#PipelineResource: {
	metav1.#TypeMeta

	// +optional
	metadata?: metav1.#ObjectMeta @go(ObjectMeta)

	// Spec holds the desired state of the PipelineResource from the client
	spec?: #PipelineResourceSpec @go(Spec)

	// Status is deprecated.
	// It usually is used to communicate the observed state of the PipelineResource from
	// the controller, but was unused as there is no controller for PipelineResource.
	// +optional
	status?: null | #PipelineResourceStatus @go(Status,*PipelineResourceStatus)
}

// PipelineResourceStatus does not contain anything because PipelineResources on their own
// do not have a status
// Deprecated
#PipelineResourceStatus: {
}

// PipelineResourceSpec defines  an individual resources used in the pipeline.
#PipelineResourceSpec: {
	// Description is a user-facing description of the resource that may be
	// used to populate a UI.
	// +optional
	description?: string @go(Description)
	type:         string @go(Type)

	// +listType=atomic
	params: [...#ResourceParam] @go(Params,[]ResourceParam)

	// Secrets to fetch to populate some of resource fields
	// +optional
	// +listType=atomic
	secrets?: [...#SecretParam] @go(SecretParams,[]SecretParam)
}

// SecretParam indicates which secret can be used to populate a field of the resource
#SecretParam: {
	fieldName:  string @go(FieldName)
	secretKey:  string @go(SecretKey)
	secretName: string @go(SecretName)
}

// ResourceParam declares a string value to use for the parameter called Name, and is used in
// the specific context of PipelineResources.
#ResourceParam: {
	name:  string @go(Name)
	value: string @go(Value)
}

// ResourceDeclaration defines an input or output PipelineResource declared as a requirement
// by another type such as a Task or Condition. The Name field will be used to refer to these
// PipelineResources within the type's definition, and when provided as an Input, the Name will be the
// path to the volume mounted containing this PipelineResource as an input (e.g.
// an input Resource named `workspace` will be mounted at `/workspace`).
#ResourceDeclaration: {
	// Name declares the name by which a resource is referenced in the
	// definition. Resources may be referenced by name in the definition of a
	// Task's steps.
	name: string @go(Name)

	// Type is the type of this resource;
	type: string @go(Type)

	// Description is a user-facing description of the declared resource that may be
	// used to populate a UI.
	// +optional
	description?: string @go(Description)

	// TargetPath is the path in workspace directory where the resource
	// will be copied.
	// +optional
	targetPath?: string @go(TargetPath)

	// Optional declares the resource as optional.
	// By default optional is set to false which makes a resource required.
	// optional: true - the resource is considered optional
	// optional: false - the resource is considered required (equivalent of not specifying it)
	optional?: bool @go(Optional)
}

// PipelineResourceList contains a list of PipelineResources
#PipelineResourceList: {
	metav1.#TypeMeta

	// +optional
	metadata?: metav1.#ListMeta @go(ListMeta)
	items: [...#PipelineResource] @go(Items,[]PipelineResource)
}
