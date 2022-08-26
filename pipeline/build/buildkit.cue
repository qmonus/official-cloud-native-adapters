package buildkit

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:authregist"
	"qmonus.net/adapter/official/pipeline/tasks:buildkitBuild"
)

DesignPattern: {
	name: "build:buildkit"

	pipelineParameters: {
		image: string | *""
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_buildTask:           string
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
				"checkout":     gitCheckout.#Builder
				"authenticate": authregist.#Builder & {
					input: {
						image: _imageName
					}
					runAfter: ["checkout"]
				}
				"\(_buildTask)": buildkitBuild.#Builder & {
					input: {
						image: _imageName
					}
					runAfter: ["authenticate"]
				}
			}
			results: {
				"\(_imageFullNameTag)":    tasks["\(_buildTask)"].results.imageFullNameTag
				"\(_imageFullNameDigest)": tasks["\(_buildTask)"].results.imageFullNameDigest
			}
		}
	}
}
