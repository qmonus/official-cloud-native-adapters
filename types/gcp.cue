package gcp

import "qmonus.net/adapter/official/types:base"

#GcpProvider: {
	base.#Resource
	type: "pulumi:providers:gcp"
}

#QvsManagedLabel: {
	"managed-by": "qmonus_value_stream"
	{[string]: string}
}

#GcpArtifactRegistry: {
	base.#Resource
	type: "gcp:artifactregistry:Repository"
	properties: labels: #QvsManagedLabel
}

#GcpCloudNatGateway: {
	base.#Resource
	type: "gcp:compute:RouterNat"
}

#GcpCloudRouter: {
	base.#Resource
	type: "gcp:compute:Router"
}

#GcpCloudSqlInstance: {
	base.#Resource
	type: "gcp:sql:DatabaseInstance"
	properties: settings: {
		userLabels: #QvsManagedLabel
		{[string]: _}
	}
}

#GcpCloudSqlUser: {
	base.#Resource
	type: "gcp:sql:User"
}

#GcpGkeCluster: {
	base.#Resource
	type: "gcp:container:Cluster"
	properties: resourceLabels: #QvsManagedLabel
}

#GcpGkeNodepool: {
	base.#Resource
	type: "gcp:container:NodePool"
	properties: nodeConfig: {
		resourceLabels: #QvsManagedLabel
		{[string]: _}
	}
}

#GcpIamMember: {
	base.#Resource
	type: "gcp:projects:IAMMember"
	// for this resource, "project" needs to be specified explicitly
	// because it is not inferred from the "gcp" provider project configuration
	properties: project: string
}

#GcpIpAddress: {
	base.#Resource
	type: "gcp:compute:Address"
	properties: labels: #QvsManagedLabel
}

#GcpSecretManagerSecret: {
	base.#Resource
	type: "gcp:secretmanager:Secret"
	properties: labels: #QvsManagedLabel
}

#GcpSecretManagerSecretVersion: {
	base.#Resource
	type: "gcp:secretmanager:SecretVersion"
}

#GcpServiceAccount: {
	base.#Resource
	type: "gcp:serviceaccount/account:Account"
}

#GcpServiceAccountIamBinding: {
	base.#Resource
	type: "gcp:serviceaccount/iAMBinding:IAMBinding"
}

#GcpSubnet: {
	base.#Resource
	type: "gcp:compute:Subnetwork"
}

#GcpVpcNetwork: {
	base.#Resource
	type: "gcp:compute:Network"
}
