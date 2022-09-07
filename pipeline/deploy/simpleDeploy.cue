package simpleDeploy

import (
	"qmonus.net/adapter/official/pipeline/deploy:simple"
)

DesignPattern: {
	name: "deploy:simpleDeploy"

	pipelineParameters: {
		useDebug: bool | *false
	}

	composites: [
		{
			pattern: simple.DesignPattern
			pipelineParams: {
				useDebug:    pipelineParameters.useDebug
				deployPhase: "app"
			}
		},
	]
	pipelines: _
}
