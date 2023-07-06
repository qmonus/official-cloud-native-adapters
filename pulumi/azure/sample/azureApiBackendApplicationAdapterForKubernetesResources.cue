package azureApiBackendApplicationAdapterForKubernetesResources

import (
	"qmonus.net/adapter/official/pulumi/base/kubernetes"
	"qmonus.net/adapter/official/kubernetes/sample:azureApiBackendApplicationAdapterForKubernetesResources"
)

#K8sParameters: azureApiBackendApplicationAdapterForKubernetesResources.DesignPattern.parameters

DesignPattern: {
	name: "kubernetes:azureApiBackendApplicationAdapterForKubernetesResources"
	parameters: {
		#K8sParameters
		k8sProvider: string | *"\(kubernetes.default.provider)"
		...
	}

	group:   string
	_prefix: string | *""
	if group != _|_ {
		_prefix: "\(group)/"
	}
	let _suffix = parameters.appName

	let _ingress = "\(_prefix)ingress/\(_suffix)"
	let _service = "\(_prefix)service/\(_suffix)"
	let _deployment = "\(_prefix)deployment/\(_suffix)"
	let _certificate = "\(_prefix)certificate/\(_suffix)"
	let _secret = "\(_prefix)secret/\(_suffix)"

	let _resources = {
		azureApiBackendApplicationAdapterForKubernetesResources.DesignPattern
		"parameters": parameters
	}.resources

	resources: app: "\(_ingress)": kubernetes.#Resource & {
		type: "kubernetes:networking.k8s.io/v1:Ingress"
		options: provider: "${\(parameters.k8sProvider)}"
		properties: {
			metadata: _resources.app.ingress.metadata
			spec:     _resources.app.ingress.spec
		}
	}
	resources: app: "\(_service)": kubernetes.#Resource & {
		type: "kubernetes:core/v1:Service"
		options: provider: "${\(parameters.k8sProvider)}"
		properties: {
			metadata: _resources.app.service.metadata
			spec:     _resources.app.service.spec
		}
	}
	resources: app: "\(_deployment)": kubernetes.#Resource & {
		type: "kubernetes:apps/v1:Deployment"
		options: provider: "${\(parameters.k8sProvider)}"
		properties: {
			metadata: _resources.app.deployment.metadata
			spec:     _resources.app.deployment.spec
		}
	}
	resources: app: "\(_certificate)": kubernetes.#Resource & {
		type: "kubernetes:apiextensions.k8s.io:CustomResource"
		options: provider: "${\(parameters.k8sProvider)}"
		properties: {
			apiVersion: _resources.app.certificate.apiVersion
			kind:       _resources.app.certificate.kind
			metadata:   _resources.app.certificate.metadata
			spec:       _resources.app.certificate.spec
		}
	}
	resources: app: "\(_secret)": kubernetes.#Resource & {
		type: "kubernetes:apiextensions.k8s.io:CustomResource"
		options: provider: "${\(parameters.k8sProvider)}"
		properties: {
			apiVersion: _resources.app.externalSecret.apiVersion
			kind:       _resources.app.externalSecret.kind
			metadata:   _resources.app.externalSecret.metadata
			spec:       _resources.app.externalSecret.spec
		}
	}

}
