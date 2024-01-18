package base

#ResourceBase: {
	// cloud provider
	provider: string

	// API schema
	apiVersion: string
	kind:       string

	// metadata
	metadata: {
		name: string
		{[string]: _}
	}

	// output to save
	output: [...string]
}

#ResourceSpec: {
	#ResourceBase

	// any resource specific configuration
	{[string]: _}
}

#CompositeDef: {
	// design pattern to composite
	pattern: #DesignPattern

	// parameters to bind on composite
	params: {[string]: _}

	// parameters for the pipeline to bind on composite
	pipelineParams?: {[string]: _}

	// group composited resource to isolate from others
	group?: string
}

#ResourceOutput: {
	// application setup stage
	appSetup?: {[string]: #ResourceSpec}

	// application deployment stage
	app?: {[string]: #ResourceSpec}
}

#DesignPattern: {
	name:        string
	description: string | *""

	// input parameters
	parameters: {[string]: _}

	// input parameters for pipeline
	pipelineParameters?: {[string]: _}

	// enumerates design pattern
	composites?: [...#CompositeDef]

	// whether to group resources after composite
	group: string | *""

	// resource declaration
	resources?: #ResourceOutput

	// pipeline declaration
	pipelines?: {[string]: _}

	// lazy evaluation
	defer?: {
		#ResourceOutput
	}

	// exported values
	outputs?: {[string]: _}
}

#Call: #DesignPattern & {
	name: string
	parameters: {[string]: _}
	pipelineParameters?: {[string]: _}
	resources: #ResourceOutput
	#done:     bool
}
