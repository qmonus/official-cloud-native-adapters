package trivyGcp

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:trivyImageScanGcp"
)

DesignPattern: {
	pipelineParameters: {
		image:             string | *""
		sbomFormat:        string | *"cyclonedx"
		uploadScanResults: bool | *false
		shouldNotify:      bool | *false
		resourcePriority:  "high" | *"medium"
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_scanTask:   string
	_resultsURL: string

	if pipelineParameters.image != "" {
		_scanTask: {
			utils.#concatKebab
			input: [_imageName, "image-scan-gcp"]
		}.out
		_resultsURL: {
			utils.#addPrefix
			prefix: _imageName
			key:    "uploadedScanResultsUrl"
		}.out
	}
	if pipelineParameters.image == "" {
		_scanTask:   "image-scan-gcp"
		_resultsURL: "uploadedScanResultsUrl"
	}

	pipelines: {
		scan: {
			tasks: {
				"\(_scanTask)": {
					trivyImageScanGcp.#Builder & {
						input: {
							image:             _imageName
							sbomFormat:        pipelineParameters.sbomFormat
							uploadScanResults: pipelineParameters.uploadScanResults
							shouldNotify:      pipelineParameters.shouldNotify
							resourcePriority:  pipelineParameters.resourcePriority
						}
					}
				}
			}
			if pipelineParameters.uploadScanResults {
				results: {
					"\(_resultsURL)": tasks["\(_scanTask)"].results.uploadedScanResultsUrl
				}
			}
		}
	}
}
