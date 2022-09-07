package clustersecretstore

import (
	"qmonus.net/adapter/official/kubernetes:types"
)

DesignPattern: {
	name: "gke:clustersecretstore"

	parameters: {
		appName:              string | *"gcp-secret-manager"
		smGcpProject:         string
		gsaGcpProject:        string | *smGcpProject
		k8sClusterGcpProject: string | *smGcpProject
		gsaName:              string | *"external-secrets-operator"
		ksaNamespace:         string | *"qmonus-system"
		k8sClusterLocation:   string
		k8sClusterName:       string
	}

	resources: app: {
		serviceaccount:     _serviceaccount
		clustersecretstore: _clustersecretstore
	}

	_serviceaccount: types.#ServiceAccount & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.ksaNamespace
			annotations: {
				"iam.gke.io/gcp-service-account": "\(parameters.gsaName)@\(parameters.gsaGcpProject).iam.gserviceaccount.com"
			}
		}
	}

	_clustersecretstore: types.#ClusterSecretStore & {
		metadata: name: parameters.appName
		spec: {
			provider: gcpsm: {
				projectID: parameters.smGcpProject
				auth: workloadIdentity: {
					clusterLocation:  parameters.k8sClusterLocation
					clusterName:      parameters.k8sClusterName
					clusterProjectID: parameters.k8sClusterGcpProject
					serviceAccountRef: {
						name:      parameters.appName
						namespace: parameters.ksaNamespace
					}
				}
			}
		}
	}
}
