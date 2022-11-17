package simpleSetup

import (
	"qmonus.net/adapter/official/pipeline/deploy:simple"
)

DesignPattern: {
	name: "deploy:simpleSetup"

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
				deployPhase:      "setup"
				resourcePriority: pipelineParameters.resourcePriority
			}
		},
	]
	pipelines: _
}
