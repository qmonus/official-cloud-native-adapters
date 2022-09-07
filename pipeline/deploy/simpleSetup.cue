package simpleSetup

import (
	"qmonus.net/adapter/official/pipeline/deploy:simple"
)

DesignPattern: {
	name: "deploy:simpleSetup"

	pipelineParameters: {
		useDebug: bool | *false
	}

	composites: [
		{
			pattern: simple.DesignPattern
			pipelineParams: {
				useDebug:    pipelineParameters.useDebug
				deployPhase: "setup"
			}
		},
	]
	pipelines: _
}
