package clustersecretstore

import (
	"qmonus.net/adapter/official/kubernetes:types"
)

DesignPattern: {
	name: "aks:clustersecretstore"

	parameters: {
		appName:               string | *"azure-key-vault"
		azureKeyContainerName: string
		ksaName:               string | *"azure-key-vault"
		ksaNamespace:          string | *"qmonus-system"
	}

	resources: app: {
		clustersecretstore: _clustersecretstore
	}

	_clustersecretstore: types.#ClusterSecretStore & {
		metadata: name: parameters.appName
		spec: {
			provider: azurekv: {
				authType: "WorkloadIdentity"
				vaultUrl: "https://\(parameters.azureKeyContainerName).vault.azure.net/"
				serviceAccountRef: {
					name:      parameters.ksaName
					namespace: parameters.ksaNamespace
				}
			}
		}
	}
}
