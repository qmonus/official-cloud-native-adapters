// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/external-secrets/external-secrets/apis/externalsecrets/v1beta1

package v1beta1

import esmeta "github.com/external-secrets/external-secrets/apis/meta/v1"

// Configures an store to sync secrets using a IBM Cloud Secrets Manager
// backend.
#IBMProvider: {
	// Auth configures how secret-manager authenticates with the IBM secrets manager.
	auth: #IBMAuth @go(Auth)

	// ServiceURL is the Endpoint URL that is specific to the Secrets Manager service instance
	serviceUrl?: null | string @go(ServiceURL,*string)
}

#IBMAuth: {
	secretRef: #IBMAuthSecretRef @go(SecretRef)
}

#IBMAuthSecretRef: {
	// The SecretAccessKey is used for authentication
	// +optional
	secretApiKeySecretRef?: esmeta.#SecretKeySelector @go(SecretAPIKey)
}
