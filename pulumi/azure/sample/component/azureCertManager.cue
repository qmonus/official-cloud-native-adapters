package azureCertManager

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureCertManager"

	parameters: {
		appName:             string | *"sample"
		azureSubscriptionId: string
		certmanagerVersion:  string | *"1.11.4"
	}

	_azureProvider: provider: "${AzureProvider}"
	_k8sProvider: provider:   "${K8sProvider}"

	resources: app: {
		certmanagerNamespace: azure.#Resource & {
			type: "kubernetes:core/v1:Namespace"
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

		certmanager: azure.#Resource & {
			type: "kubernetes:helm.sh/v3:Release"
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

		clusterIssuer: azure.#Resource & {
			type: "kubernetes:apiextensions.k8s.io:CustomResource"
			options: {
				dependsOn: ["${certmanager}", "${dnsZone}"]
				_k8sProvider
			}
			properties: {
				apiVersion: "cert-manager.io/v1"
				kind:       "ClusterIssuer"
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
									hostedZoneName: "${dnsZone.name}"
									managedIdentity: {
										clientID: "${certmanagerUserAssignedIdentity.clientId}"
									}
									resourceGroupName: "${resourceGroup.name}"
									subscriptionID:    "\(parameters.azureSubscriptionId)"
								}
							}
						}]
					}
				}
			}
		}

		certmanagerUserAssignedIdentity: azure.#Resource & {
			type:    "azure-native:managedidentity:UserAssignedIdentity"
			options: _azureProvider
			properties: {
				location:          "japaneast"
				resourceGroupName: "${resourceGroup.name}"
				resourceName:      "qvs-\(parameters.appName)-certmanager-user-assigned-identity"
				tags: {
					"managed-by": "Qmonus Value Stream"
				}
			}
		}

		certmanagerRoleAssignment: azure.#Resource & {
			type: "azure-native:authorization:RoleAssignment"
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

		certmanagerFederatedIdentityCredentials: azure.#Resource & {
			type:    "azure-native:managedidentity:FederatedIdentityCredential"
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
