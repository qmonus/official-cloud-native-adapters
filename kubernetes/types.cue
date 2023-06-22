package types

import (
	"qmonus.net/adapter/official/base"

	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	networkingv1 "k8s.io/api/networking/v1"
	backendconfigv1 "k8s.io/ingress-gce/pkg/apis/backendconfig/v1"
	frontendconfigv1beta1 "k8s.io/ingress-gce/pkg/apis/frontendconfig/v1beta1"
	networkingGkev1 "github.com/GoogleCloudPlatform/gke-managed-certs/pkg/apis/networking.gke.io/v1"
	externalsecretsv1beta1 "github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1"
	certmanagerv1 "github.com/cert-manager/cert-manager/pkg/apis/certmanager/v1"
)

_KubernetesResource: {
	provider: "kubernetes"

	// leaving namespace blank is not a good practice
	metadata: namespace: string
}

_KubernetesClusteredResource: {
	provider: "kubernetes"
}

#Namespace: _KubernetesClusteredResource & {
	base.#ResourceBase
	corev1.#Namespace

	apiVersion: "v1"
	kind:       "Namespace"
}

#Deployment: _KubernetesResource & {
	base.#ResourceBase
	appsv1.#Deployment

	apiVersion: "apps/v1"
	kind:       "Deployment"
}

#Service: _KubernetesResource & {
	base.#ResourceBase
	corev1.#Service

	apiVersion: "v1"
	kind:       "Service"
}

#Ingress: _KubernetesResource & {
	base.#ResourceBase
	networkingv1.#Ingress

	apiVersion: "networking.k8s.io/v1"
	kind:       "Ingress"
}

#BackendConfig: _KubernetesResource & {
	base.#ResourceBase
	backendconfigv1.#BackendConfig

	apiVersion: "cloud.google.com/v1"
	kind:       "BackendConfig"
}

#FrontendConfig: _KubernetesResource & {
	base.#ResourceBase
	frontendconfigv1beta1.#FrontendConfig

	apiVersion: "networking.gke.io/v1beta1"
	kind:       "FrontendConfig"
}

#ManagedCertificate: _KubernetesResource & {
	base.#ResourceBase
	networkingGkev1.#ManagedCertificate

	apiVersion: "networking.gke.io/v1"
	kind:       "ManagedCertificate"
}

#ServiceAccount: _KubernetesResource & {
	base.#ResourceBase
	corev1.#ServiceAccount

	apiVersion: "v1"
	kind:       "ServiceAccount"
}

#ClusterSecretStore: _KubernetesClusteredResource & {
	base.#ResourceBase
	externalsecretsv1beta1.#ClusterSecretStore

	apiVersion: "external-secrets.io/v1beta1"
	kind:       "ClusterSecretStore"
	spec: {
		controller:      ""
		refreshInterval: 300
	}
}

#ExternalSecret: _KubernetesResource & {
	base.#ResourceBase
	externalsecretsv1beta1.#ExternalSecret

	apiVersion: "external-secrets.io/v1beta1"
	kind:       "ExternalSecret"
}

#Certificate: _KubernetesResource & {
	base.#ResourceBase
	certmanagerv1.#Certificate

	apiVersion: "cert-manager.io/v1"
	kind:       "Certificate"
}

#ChartOpts: {
	provider:  "kubernetes-helm"
	chart:     string
	fetchOpts: #FetchOpts
	...
}

#FetchOpts: {
	repo: string
	...
}
