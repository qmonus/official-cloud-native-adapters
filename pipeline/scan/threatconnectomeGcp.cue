package threatconnectomeGcp

import (
	task "qmonus.net/adapter/official/pipeline/tasks:threatconnectomeGcp"
)

DesignPattern: {
	name: "imageScan:threatconnectome"
	pipelineParameters: {
		groupName: string | *""
	}
	pipelines: {
		threatconnectome: {
			tasks: {
				"threatconnectome": task.#Builder & {
					input: pipelineParameters
				}
			}
		}
	}
}
