package trivyAzure

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:trivyImageScanAzure"
)

DesignPattern: {
	pipelineParameters: {
		image:            string | *""
		shouldNotify:     bool | *false
		resourcePriority: "high" | *"medium"
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_scanTask: string

	if pipelineParameters.image != "" {
		_scanTask: {
			utils.#concatkebab
			input: [_imageName, "image-scan-azure"]
		}.out
	}
	if pipelineParameters.image == "" {
		_scanTask: "image-scan-azure"
	}

	pipelines: {
		scan: {
			tasks: {
				"\(_scanTask)": {
					trivyImageScanAzure.#Builder & {
						input: {
							shouldNotify:     pipelineParameters.shouldNotify
							resourcePriority: pipelineParameters.resourcePriority
						}
					}
				}
			}
		}
	}
}
