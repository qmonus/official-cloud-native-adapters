package imagePromoteGcp

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:gcraneImagePromote"
)

DesignPattern: {
	name: "utils:imagePromoteGcp"

	pipelineParameters: {
		image: string | *""
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_loginTask:           string
	_promoteTask:         string
	_imageFullNameTag:    string
	_imageFullNameDigest: string
	_imageDigest:         string

	if pipelineParameters.image != "" {
		_promoteTask: {
			utils.#concatKebab
			input: [_imageName, "promote"]
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
		_imageDigest: {
			utils.#addPrefix
			prefix: _imageName
			key:    "imageDigest"
		}.out
	}
	if pipelineParameters.image == "" {
		_promoteTask:         "promote"
		_imageFullNameTag:    "imageFullNameTag"
		_imageFullNameDigest: "imageFullNameDigest"
		_imageDigest:         "imageDigest"
	}

	pipelines: {
		promote: {
			tasks: {
				"\(_promoteTask)": gcraneImagePromote.#Builder & {
					input: {
						image: _imageName
					}
				}
			}
			results: {
				"\(_imageFullNameTag)":    tasks["\(_promoteTask)"].results.imageFullNameTag
				"\(_imageFullNameDigest)": tasks["\(_promoteTask)"].results.imageFullNameDigest
				"\(_imageDigest)":         tasks["\(_promoteTask)"].results.imageDigest
			}
		}
	}
}
