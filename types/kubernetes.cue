package kubernetes

import "qmonus.net/adapter/official/types:base"

#K8sResource: {
	properties: metadata?: {
		name:       string
		namespace?: string
		{[string]: _}
	}
}

#K8sProvider: {
	base.#Resource
	type: "pulumi:providers:kubernetes"
}

#K8sDeployment: {
	base.#Resource
	#K8sResource
	type: "kubernetes:apps/v1:Deployment"
}

#K8sService: {
	base.#Resource
	#K8sResource
	type: "kubernetes:core/v1:Service"
}

#K8sHelmRelease: {
	base.#Resource
	#K8sResource
	type: "kubernetes:helm.sh/v3:Release"
}

#K8sIngress: {
	base.#Resource
	#K8sResource
	type: "kubernetes:networking.k8s.io/v1:Ingress"
}

#K8sNamespace: {
	base.#Resource
	#K8sResource
	type: "kubernetes:core/v1:Namespace"
}

#K8sServiceAccount: {
	base.#Resource
	#K8sResource
	type: "kubernetes:core/v1:ServiceAccount"
}

#K8sCustomResource: {
	base.#Resource
	#K8sResource
	type: "kubernetes:apiextensions.k8s.io:CustomResource"
}

#K8sBackendConfig: {
	#K8sCustomResource
	properties: {
		apiVersion: "cloud.google.com/v1"
		kind:       "BackendConfig"
	}
}

#K8sCertificate: {
	#K8sCustomResource
	properties: {
		apiVersion: "cert-manager.io/v1"
		kind:       "Certificate"
	}
}

#K8sClusterIssuer: {
	#K8sCustomResource
	properties: {
		apiVersion: "cert-manager.io/v1"
		kind:       "ClusterIssuer"
	}
}

#K8sClusterSecretStore: {
	#K8sCustomResource
	properties: {
		apiVersion: "external-secrets.io/v1beta1"
		kind:       "ClusterSecretStore"
	}
}

#K8sExternalSecret: {
	#K8sCustomResource
	properties: {
		apiVersion: "external-secrets.io/v1beta1"
		kind:       "ExternalSecret"
	}
}

#K8sManagedCertificate: {
	#K8sCustomResource
	properties: {
		apiVersion: "networking.gke.io/v1"
		kind:       "ManagedCertificate"
	}
}
