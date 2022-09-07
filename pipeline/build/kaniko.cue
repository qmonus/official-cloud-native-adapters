package kaniko

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:kanikoBuild"
)

DesignPattern: {
	name: "build:kaniko"

	pipelineParameters: {
		image: string | *""
		buildArgs: [string]: {
			name:    string
			default: string
		}
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_buildTask:           string
	_imageFullName:       string
	_imageFullNameTag:    string
	_imageFullNameDigest: string
	if pipelineParameters.image != "" {
		_buildTask: {
			utils.#concatKebab
			input: [_imageName, "build"]
		}.out
		_imageFullNameTag: {
			utils.#addPrefix
			prefix: _imageName
			key:    "imageFullNameTag"
		}.out
		_imageFullNameDigest: {
			utils.#addPrefix
			prefix: _imageName
			key:    "imageFullNameDigest"
		}.out
	}
	if pipelineParameters.image == "" {
		_buildTask:           "build"
		_imageFullNameTag:    "imageFullNameTag"
		_imageFullNameDigest: "imageFullNameDigest"
	}

	pipelines: {
		build: {
			tasks: {
				"checkout":      gitCheckout.#Builder
				"\(_buildTask)": kanikoBuild.#Builder & {
					input: {
						image:     _imageName
						buildArgs: pipelineParameters.buildArgs
					}
					runAfter: ["checkout"]
				}
			}
			results: {
				"\(_imageFullNameTag)":    tasks["\(_buildTask)"].results.imageFullNameTag
				"\(_imageFullNameDigest)": tasks["\(_buildTask)"].results.imageFullNameDigest
			}
		}
	}
}
