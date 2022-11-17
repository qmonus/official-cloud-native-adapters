package simpleDeploy

import (
	"qmonus.net/adapter/official/pipeline/deploy:simple"
)

DesignPattern: {
	name: "deploy:simpleDeploy"

	pipelineParameters: {
		repositoryKind:   string | *""
		useDebug:         bool | *false
		resourcePriority: "high" | *"medium"
	}

	composites: [
		{
			pattern: simple.DesignPattern
			pipelineParams: {
				repositoryKind:   pipelineParameters.repositoryKind
				useDebug:         pipelineParameters.useDebug
				deployPhase:      "app"
				resourcePriority: pipelineParameters.resourcePriority
			}
		},
	]
	pipelines: _
}
