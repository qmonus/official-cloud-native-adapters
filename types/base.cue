package base

#Resource: {
	type: string
	properties?: {[string]: _}
	options?: {[string]: _}

	// required for qvsctl compile.
	provider: "pulumi-yaml"
	{[string]: _}
}

#QvsManagedLabel: {
	"managed-by": "Qmonus Value Stream"
	...
}
