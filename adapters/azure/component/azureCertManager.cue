package azureCertManager

import (
	"qmonus.net/adapter/official/types:azure"
	"qmonus.net/adapter/official/types:kubernetes"
)

DesignPattern: {
	parameters: {
		appName:                       string | *"sample"
		dnsZoneName:                   string
		azureDnsZoneResourceGroupName: string
		azureSubscriptionId:           string
		certmanagerVersion:            string | *"1.11.4"
	}

	_azureProvider: provider: "${AzureProvider}"
	_k8sProvider: provider:   "${K8sProvider}"

	resources: app: {
		certmanagerNamespace: kubernetes.#K8sNamespace & {
			options: {
				dependsOn: ["${kubernetesCluster}"]
				_k8sProvider
			}
			properties: {
				metadata: {
					name: "cert-manager"
				}
			}
		}

		certmanager: kubernetes.#K8sHelmRelease & {
			options: {
				dependsOn: ["${certmanagerNamespace}"]
				_k8sProvider
			}
			properties: {
				chart:     "cert-manager"
				version:   "\(parameters.certmanagerVersion)"
				namespace: "${certmanagerNamespace.metadata.name}"
				repositoryOpts: {
					repo: "https://charts.jetstack.io"
				}
				values: {
					installCRDs: true
					podLabels: {
						"azure.workload.identity/use": "true"
					}
					serviceAccount: {
						name: "qvs-certmanager-sa"
						labels: {
							"azure.workload.identity/use": "true"
						}
					}
				}
			}
		}

		clusterIssuer: kubernetes.#K8sClusterIssuer & {
			options: {
				dependsOn: ["${certmanager}"]
				_k8sProvider
			}
			properties: {
				metadata: {
					namespace: "${certmanagerNamespace.metadata.name}"
					name:      "qvs-cluster-issuer"
				}
				spec: {
					acme: {
						privateKeySecretRef: {
							name: "letsencrypt-private-key"
						}
						server: "https://acme-v02.api.letsencrypt.org/directory"
						solvers: [{
							dns01: {
								azureDNS: {
									environment:    "AzurePublicCloud"
									hostedZoneName: parameters.dnsZoneName
									managedIdentity: {
										clientID: "${certmanagerUserAssignedIdentity.clientId}"
									}
									resourceGroupName: parameters.azureDnsZoneResourceGroupName
									subscriptionID:    "\(parameters.azureSubscriptionId)"
								}
							}
						}]
					}
				}
			}
		}

		certmanagerUserAssignedIdentity: azure.#AzureUserAssignedIdentity & {
			options: _azureProvider
			properties: {
				location:          "japaneast"
				resourceGroupName: "${resourceGroup.name}"
				resourceName:      "qvs-\(parameters.appName)-certmanager-user-assigned-identity"
			}
		}

		certmanagerRoleAssignment: azure.#AzureRoleAssignment & {
			options: {
				dependsOn: ["${certmanagerUserAssignedIdentity}"]
				_azureProvider
			}
			properties: {
				scope:            "/subscriptions/\(parameters.azureSubscriptionId)"
				roleDefinitionId: "/subscriptions/\(parameters.azureSubscriptionId)/providers/Microsoft.Authorization/roleDefinitions/befefa01-2a29-4197-83a8-272ff33ce314"
				principalId:      "${certmanagerUserAssignedIdentity.principalId}"
				principalType:    "ServicePrincipal"
			}
		}

		certmanagerFederatedIdentityCredentials: azure.#AzureFederatedIdentityCredential & {
			options: _azureProvider
			properties: {
				audiences: ["api://AzureADTokenExchange"]
				federatedIdentityCredentialResourceName: "qvs-\(parameters.appName)-certmanager-federated-identity-credentials"
				issuer:                                  "${kubernetesCluster.oidcIssuerUrl}"
				resourceGroupName:                       "${resourceGroup.name}"
				resourceName:                            "${certmanagerUserAssignedIdentity.name}"
				subject:                                 "system:serviceaccount:${certmanagerNamespace.metadata.name}:qvs-certmanager-sa"
			}
		}
	}
}
