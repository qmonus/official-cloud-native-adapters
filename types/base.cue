package base

#Resource: {
	type: string
	properties?: {[string]: _}
	options?: {[string]: _}

	// required for qvsctl compile.
	provider: "pulumi-yaml"
	{[string]: _}
}

#Secret: {
	key:      string
	version?: string
}
