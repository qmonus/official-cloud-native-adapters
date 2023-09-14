package azureExternalSecrets

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
)

DesignPattern: {
	name: "sample:azureExternalSecrets"
	parameters: {
		appName:       string | *"sample"
		azureTenantId: string
		esoVersion:    string | *"0.9.0"
	}

	_azureProvider: provider:        "${AzureProvider}"
	_azureClaasicProvider: provider: "${AzureClassicProvider}"
	_k8sProvider: provider:          "${K8sProvider}"

	resources: app: {
		esoNamespace: azure.#Resource & {
			type: "kubernetes:core/v1:Namespace"
			options: {
				dependsOn: ["${kubernetesCluster}"]
				_k8sProvider
			}
			properties: {
				metadata: {
					name: "external-secrets"
				}
			}
		}

		eso: azure.#Resource & {
			type: "kubernetes:helm.sh/v3:Release"
			options: {
				dependsOn: ["${esoNamespace}"]
				_k8sProvider
			}
			properties: {
				chart:     "external-secrets"
				version:   "\(parameters.esoVersion)"
				namespace: "${esoNamespace.metadata.name}"
				repositoryOpts: {
					repo: "https://charts.external-secrets.io"
				}
				values: {
					installCRDs: true
					podLabels: {
						"azure.workload.identity/use": "true"
					}
					serviceAccount: {
						name: "qvs-eso-sa"
						annotations: {
							"azure.workload.identity/client-id": "${esoUserAssignedIdentity.clientId}"
							"azure.workload.identity/tenant-id": "\(parameters.azureTenantId)"
						}
						extraLabels: {
							"azure.workload.identity/use": "true"
						}
					}
				}
			}
		}

		clusterSecretStore: azure.#Resource & {
			type: "kubernetes:apiextensions.k8s.io:CustomResource"
			options: {
				dependsOn: ["${eso}"]
				_k8sProvider
			}
			properties: {
				apiVersion: "external-secrets.io/v1beta1"
				kind:       "ClusterSecretStore"
				metadata: {
					name:      "qvs-global-azure-store"
					namespace: "${esoNamespace.metadata.name}"
				}
				spec: {
					provider: {
						azurekv: {
							authType: "WorkloadIdentity"
							vaultUrl:
								"fn::invoke": {
									function: "azure:keyvault:getKeyVault"
									arguments: {
										name:              "${keyVault.name}"
										resourceGroupName: "${resourceGroup.name}"
									}
									return: "vaultUri"
								}
							serviceAccountRef: {
								name:      "qvs-eso-sa"
								namespace: "${esoNamespace.metadata.name}"
							}
						}
					}
				}
			}
		}

		esoUserAssignedIdentity: azure.#Resource & {
			type:    "azure-native:managedidentity:UserAssignedIdentity"
			options: _azureProvider
			properties: {
				location:          "japaneast"
				resourceGroupName: "${resourceGroup.name}"
				resourceName:      "qvs-\(parameters.appName)-eso-user-assigned-identity"
				tags: {
					"managed-by": "Qmonus Value Stream"
				}
			}
		}

		esFederatedIdentityCredentials: azure.#Resource & {
			type:    "azure-native:managedidentity:FederatedIdentityCredential"
			options: _azureProvider
			properties: {
				audiences: ["api://AzureADTokenExchange"]
				federatedIdentityCredentialResourceName: "qvs-\(parameters.appName)-eso-federated-identity-credentials"
				issuer:                                  "${kubernetesCluster.oidcIssuerUrl}"
				resourceGroupName:                       "${resourceGroup.name}"
				resourceName:                            "${esoUserAssignedIdentity.name}"
				subject:                                 "system:serviceaccount:${esoNamespace.metadata.name}:qvs-eso-sa"
			}
		}

		keyVaultAccessPolicyForEso: azure.#Resource & {
			type:    "azure:keyvault:AccessPolicy"
			options: _azureClaasicProvider
			properties: {
				keyVaultId: "${keyVault.id}"
				tenantId:   "\(parameters.azureTenantId)"
				objectId:   "${esoUserAssignedIdentity.principalId}"
				keyPermissions: ["Get"]
				secretPermissions: ["Get"]
				certificatePermissions: ["Get"]
			}
		}
	}
}
