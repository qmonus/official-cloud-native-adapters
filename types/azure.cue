package azure

import "qmonus.net/adapter/official/types:base"

#AzureProvider: {
	base.#Resource
	type: "pulumi:providers:azure-native"
}

#AzureClassicProvider: {
	base.#Resource
	type: "pulumi:providers:azure"
}

#AzureApplicationGateway: {
	base.#Resource
	type: "azure-native:network:ApplicationGateway"
	properties: tags: base.#QvsManagedLabel
}

#AzureAppServicePlan: {
	base.#Resource
	type: "azure-native:web:AppServicePlan"
	properties: tags: base.#QvsManagedLabel
}

#AzureCacheForRedis: {
	base.#Resource
	type: "azure:redis:Cache"
	properties: tags: base.#QvsManagedLabel
}

#AzureCertificateBinding: {
	base.#Resource
	type: "azure:appservice:CertificateBinding"
}

#AzureContainerRegistry: {
	base.#Resource
	type: "azure-native:containerregistry:Registry"
	properties: tags: base.#QvsManagedLabel
}

#AzureDnsRecordSet: {
	base.#Resource
	type: "azure-native:network:RecordSet"
	properties: metadata: base.#QvsManagedLabel
}

#AzureClassicCNameRecord: {
	base.#Resource
	type: "azure:dns:CNameRecord"
	properties: tags: base.#QvsManagedLabel
}

#AzureDnsZone: {
	base.#Resource
	type: "azure-native:network:Zone"
	properties: tags: base.#QvsManagedLabel
}

#AzureFederatedIdentityCredential: {
	base.#Resource
	type: "azure-native:managedidentity:FederatedIdentityCredential"
}

#AzureKeyVault: {
	base.#Resource
	type: "azure-native:keyvault:Vault"
	properties: tags: base.#QvsManagedLabel
}

#AzureKeyVaultAccessPolicy: {
	base.#Resource
	type: "azure:keyvault:AccessPolicy"
}

#AzureKeyVaultSecret: {
	base.#Resource
	type: "azure-native:keyvault:Secret"
	properties: tags: base.#QvsManagedLabel
}

#AzureKubernetesCluster: {
	base.#Resource
	type: "azure:containerservice:KubernetesCluster"
	properties: tags: base.#QvsManagedLabel
}

#AzureOperationalinsightsWorkspace: {
	base.#Resource
	type: "azure-native:operationalinsights:Workspace"
	properties: tags: base.#QvsManagedLabel
}

#AzureManagedCertificate: {
	base.#Resource
	type: "azure:appservice:ManagedCertificate"
}

#AzureMysqlFlexibleServer: {
	base.#Resource
	type: "azure:mysql:FlexibleServer"
	properties: tags: base.#QvsManagedLabel
}

#AzureMysqlFlexibleServerFirewallRule: {
	base.#Resource
	type: "azure:mysql:FlexibleServerFirewallRule"
}

#AzureNetworkInterface: {
	base.#Resource
	type: "azure-native:network:NetworkInterface"
	properties: tags: base.#QvsManagedLabel
}

#AzureNetworkSecurityGroup: {
	base.#Resource
	type: "azure-native:network:NetworkSecurityGroup"
	properties: tags: base.#QvsManagedLabel
}

#AzurePrivateEndpoint: {
	base.#Resource
	type: "azure-native:network:PrivateEndpoint"
	properties: tags: base.#QvsManagedLabel
}

#AzurePublicIPAddress: {
	base.#Resource
	type: "azure-native:network:PublicIPAddress"
	properties: tags: base.#QvsManagedLabel
}

#AzureRedisFirewallRule: {
	base.#Resource
	type: "azure:redis:FirewallRule"
}

#AzureResourceGroup: {
	base.#Resource
	type: "azure-native:resources:ResourceGroup"
	properties: tags: base.#QvsManagedLabel
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
	properties: tags: base.#QvsManagedLabel
}

#AzureVirtualNetwork: {
	base.#Resource
	type: "azure-native:network:VirtualNetwork"
	properties: tags: base.#QvsManagedLabel
}

#AzureWebApp: {
	base.#Resource
	type: "azure-native:web:WebApp"
	properties: tags: base.#QvsManagedLabel
}

#AzureWebAppHostNameBinding: {
	base.#Resource
	type: "azure-native:web:WebAppHostNameBinding"
}

#AzureVirtualMachine: {
	base.#Resource
	type: "azure-native:compute:VirtualMachine"
	properties: tags: base.#QvsManagedLabel
}
