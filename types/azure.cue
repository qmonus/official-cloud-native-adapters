package azure

import "qmonus.net/adapter/official/types:base"

#AzureProvider: {
	base.#Resource
	type: "pulumi:providers:azure-native"
}

#QvsManagedLabel: {
	"managed-by": "Qmonus Value Stream"
	{[string]: string}
}

#AzureClassicProvider: {
	base.#Resource
	type: "pulumi:providers:azure"
}

#AzureApplicationGateway: {
	base.#Resource
	type: "azure-native:network:ApplicationGateway"
	properties: tags: #QvsManagedLabel
}

#AzureAppServicePlan: {
	base.#Resource
	type: "azure-native:web:AppServicePlan"
	properties: tags: #QvsManagedLabel
}

#AzureCacheForRedis: {
	base.#Resource
	type: "azure:redis:Cache"
	properties: tags: #QvsManagedLabel
}

#AzureCertificateBinding: {
	base.#Resource
	type: "azure:appservice:CertificateBinding"
}

#AzureContainerRegistry: {
	base.#Resource
	type: "azure-native:containerregistry:Registry"
	properties: tags: #QvsManagedLabel
}

#AzureDnsRecordSet: {
	base.#Resource
	type: "azure-native:network:RecordSet"
	properties: metadata: #QvsManagedLabel
}

#AzureClassicCNameRecord: {
	base.#Resource
	type: "azure:dns:CNameRecord"
	properties: tags: #QvsManagedLabel
}

#AzureDnsZone: {
	base.#Resource
	type: "azure-native:network:Zone"
	properties: tags: #QvsManagedLabel
}

#AzureFederatedIdentityCredential: {
	base.#Resource
	type: "azure-native:managedidentity:FederatedIdentityCredential"
}

#AzureKeyVault: {
	base.#Resource
	type: "azure-native:keyvault:Vault"
	properties: tags: #QvsManagedLabel
}

#AzureKeyVaultAccessPolicy: {
	base.#Resource
	type: "azure:keyvault:AccessPolicy"
}

#AzureKeyVaultSecret: {
	base.#Resource
	type: "azure-native:keyvault:Secret"
	properties: tags: #QvsManagedLabel
}

#AzureKubernetesCluster: {
	base.#Resource
	type: "azure:containerservice:KubernetesCluster"
	properties: tags: #QvsManagedLabel
}

#AzureOperationalinsightsWorkspace: {
	base.#Resource
	type: "azure-native:operationalinsights:Workspace"
	properties: tags: #QvsManagedLabel
}

#AzureManagedCertificate: {
	base.#Resource
	type: "azure:appservice:ManagedCertificate"
}

#AzureMysqlFlexibleServer: {
	base.#Resource
	type: "azure:mysql:FlexibleServer"
	properties: tags: #QvsManagedLabel
}

#AzureMysqlFlexibleServerFirewallRule: {
	base.#Resource
	type: "azure:mysql:FlexibleServerFirewallRule"
}

#AzureNetworkInterface: {
	base.#Resource
	type: "azure-native:network:NetworkInterface"
	properties: tags: #QvsManagedLabel
}

#AzureNetworkSecurityGroup: {
	base.#Resource
	type: "azure-native:network:NetworkSecurityGroup"
	properties: tags: #QvsManagedLabel
}

#AzurePrivateEndpoint: {
	base.#Resource
	type: "azure-native:network:PrivateEndpoint"
	properties: tags: #QvsManagedLabel
}

#AzurePublicIPAddress: {
	base.#Resource
	type: "azure-native:network:PublicIPAddress"
	properties: tags: #QvsManagedLabel
}

#AzureRedisFirewallRule: {
	base.#Resource
	type: "azure:redis:FirewallRule"
}

#AzureResourceGroup: {
	base.#Resource
	type: "azure-native:resources:ResourceGroup"
	properties: tags: #QvsManagedLabel
}

#AzureRoleAssignment: {
	base.#Resource
	type: "azure-native:authorization:RoleAssignment"
}

#AzureStaticSite: {
	base.#Resource
	type: "azure-native:web:StaticSite"
}

#AzureStaticSiteCustomDomain: {
	base.#Resource
	type: "azure-native:web:StaticSiteCustomDomain"
}

#AzureSubnet: {
	base.#Resource
	type: "azure-native:network:Subnet"
}

#AzureUserAssignedIdentity: {
	base.#Resource
	type: "azure-native:managedidentity:UserAssignedIdentity"
	properties: tags: #QvsManagedLabel
}

#AzureVirtualNetwork: {
	base.#Resource
	type: "azure-native:network:VirtualNetwork"
	properties: tags: #QvsManagedLabel
}

#AzureDiagnosticSetting: {
	base.#Resource
	type: "azure-native:insights:DiagnosticSetting"
}

#AzureWebApp: {
	base.#Resource
	type: "azure-native:web:WebApp"
	properties: tags: #QvsManagedLabel
}

#AzureWebAppHostNameBinding: {
	base.#Resource
	type: "azure-native:web:WebAppHostNameBinding"
}

#AzureVirtualMachine: {
	base.#Resource
	type: "azure-native:compute:VirtualMachine"
	properties: tags: #QvsManagedLabel
}
