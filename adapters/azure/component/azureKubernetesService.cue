package azureKubernetesService

import (
	"strconv"

	"qmonus.net/adapter/official/types:azure"
)

DesignPattern: {
	parameters: {
		appName:             string
		azureSubscriptionId: string
		// Kubernetes defualt version is latest
		kubernetesVersion:    string | *null
		kubernetesSkuTier:    "Standard" | *"Free"
		kubernetesNodeVmSize: string | *"Standard_B2s"
		kubernetesNodeCount:  string | *"1"
		kubernetesOsDiskGb:   string | *"32"
		enableContainerLog:   string | *"true"
	}

	_builtInRolesId: {
		_roleDefinitionsPath: "/providers/Microsoft.Authorization/roleDefinitions"

		// https://learn.microsoft.com/ja-jp/azure/role-based-access-control/built-in-roles#reader
		_reader: "\(_roleDefinitionsPath)/acdd72a7-3385-48ef-bd42-f606fba81ae7"

		// https://learn.microsoft.com/ja-jp/azure/role-based-access-control/built-in-roles#contributor
		_contributor: "\(_roleDefinitionsPath)/b24988ac-6180-42a0-ab88-20f7382dd24c"

		// https://learn.microsoft.com/ja-jp/azure/role-based-access-control/built-in-roles#network-contributor
		_networkContributor: "\(_roleDefinitionsPath)/4d97b98b-1d4f-4787-a291-c67834d212e7"

		// https://learn.microsoft.com/ja-jp/azure/role-based-access-control/built-in-roles#acrpull
		_acrPull: "\(_roleDefinitionsPath)/7f951dda-4ed3-4680-a7ca-43fe172d538d"
	}

	_azureClassicProvider: provider: "${AzureClassicProvider}"
	_azureProvider: provider:        "${AzureProvider}"

	let _enableContainerLog = strconv.ParseBool(parameters.enableContainerLog)

	resources: app: {
		kubernetesCluster: azure.#AzureKubernetesCluster & {
			options: _azureClassicProvider
			properties: {
				kubernetesVersion:             parameters.kubernetesVersion
				skuTier:                       parameters.kubernetesSkuTier
				resourceGroupName:             "${resourceGroup.name}"
				localAccountDisabled:          false
				location:                      "japaneast"
				name:                          "qvs-\(parameters.appName)-aks-cluster"
				roleBasedAccessControlEnabled: true
				nodeResourceGroup:             "MC-aks-node-${resourceGroup.name}"
				oidcIssuerEnabled:             true
				workloadIdentityEnabled:       true
				dnsPrefix:                     "qvs-\(parameters.appName)-aks-cluster"
				defaultNodePool: {
					vmSize:                   parameters.kubernetesNodeVmSize
					nodeCount:                strconv.Atoi(parameters.kubernetesNodeCount)
					osDiskSizeGb:             strconv.Atoi(parameters.kubernetesOsDiskGb)
					name:                     "agentpool"
					customCaTrustEnabled:     false
					enableAutoScaling:        false
					enableHostEncryption:     false
					enableNodePublicIp:       false
					fipsEnabled:              false
					enableAutoScaling:        false
					maxPods:                  100
					osDiskType:               "Managed"
					osSku:                    "Ubuntu"
					vnetSubnetId:             "${virtualNetworkAksSubnet.id}"
					temporaryNameForRotation: "temp"
					zones: [1]
				}
				identity: {
					type: "SystemAssigned"
				}
				apiServerAccessProfile: {
					authorizedIpRanges: ["0.0.0.0/0"]
				}
				ingressApplicationGateway: {
					gatewayId: "${applicationGateway.id}"
				}
				networkProfile: {
					networkPlugin: "azure"
					dnsServiceIp:  "10.0.24.10"
					ipVersions: ["IPv4"]
					networkMode:   "transparent"
					networkPolicy: "azure"
					serviceCidr:   "10.0.24.0/22"
				}
				if _enableContainerLog {
					omsAgent: {
						logAnalyticsWorkspaceId: "${logAnalyticsWorkspace.id}"
					}
				}
			}
		}

		kubeconfigSecret: azure.#AzureKeyVaultSecret & {
			options: {
				dependsOn: ["${keyVaultAccessPolicyForQvs}"]
				_azureProvider
			}
			properties: {
				properties: {
					value: "${kubernetesCluster.kubeConfigRaw}"
				}
				resourceGroupName: "${resourceGroup.name}"
				secretName:        "kubeconfig"
				vaultName:         "${keyVault.name}"
			}
		}

		agicResourceGroupReaderRoleAssignment: azure.#AzureRoleAssignment & {
			options: {
				dependsOn: ["${kubernetesCluster}"]
				_azureProvider
			}
			properties: {
				scope:            "/subscriptions/\(parameters.azureSubscriptionId)/resourceGroups/${resourceGroup.name}"
				roleDefinitionId: "/subscriptions/\(parameters.azureSubscriptionId)\(_builtInRolesId._reader)"
				principalId:      "${kubernetesCluster.ingressApplicationGateway.ingressApplicationGatewayIdentities[0].objectId}"
				principalType:    "ServicePrincipal"
			}
		}

		agicApplicationGatewayContributorRoleAssignment: azure.#AzureRoleAssignment & {
			options: {
				dependsOn: ["${kubernetesCluster}"]
				_azureProvider
			}
			properties: {
				scope:            "${applicationGateway.id}"
				roleDefinitionId: "/subscriptions/\(parameters.azureSubscriptionId)\(_builtInRolesId._contributor)"
				principalId:      "${kubernetesCluster.ingressApplicationGateway.ingressApplicationGatewayIdentities[0].objectId}"
				principalType:    "ServicePrincipal"
			}
		}

		agicApplicationGatewaySubnetNetworkContributorRoleAssignment: azure.#AzureRoleAssignment & {
			options: {
				dependsOn: ["${kubernetesCluster}"]
				_azureProvider
			}
			properties: {
				scope:            "${virtualNetworkApplicationGatewaySubnet.id}"
				roleDefinitionId: "/subscriptions/\(parameters.azureSubscriptionId)\(_builtInRolesId._networkContributor)"
				principalId:      "${kubernetesCluster.ingressApplicationGateway.ingressApplicationGatewayIdentities[0].objectId}"
				principalType:    "ServicePrincipal"
			}
		}

		acrPullRoleAssignment: azure.#AzureRoleAssignment & {
			options: _azureProvider
			properties: {
				scope:            "${containerRegistry.id}"
				roleDefinitionId: "/subscriptions/\(parameters.azureSubscriptionId)\(_builtInRolesId._acrPull)"
				principalId:      "${kubernetesCluster.kubeletIdentity.objectId}"
				principalType:    "ServicePrincipal"
			}
		}
	}
}
