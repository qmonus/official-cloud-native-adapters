package trivyGcp

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:trivyImageScanGcp"
)

DesignPattern: {
	name: "imageScan:trivyGcp"

	pipelineParameters: {
		image:        string | *""
		shouldNotify: bool | *false
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_scanTask: string

	if pipelineParameters.image != "" {
		_scanTask: {
			utils.#concatkebab
			input: [_imageName, "image-scan-gcp"]
		}.out
	}
	if pipelineParameters.image == "" {
		_scanTask: "image-scan-gcp"
	}

	pipelines: {
		scan: {
			tasks: {
				"\(_scanTask)": {
					trivyImageScanGcp.#Builder & {
						input: {
							shouldNotify: pipelineParameters.shouldNotify
						}
					}
				}
			}
		}
	}
}
