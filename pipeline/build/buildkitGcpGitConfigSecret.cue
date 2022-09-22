package buildkitGcpGitConfigSecret

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:initGitCredentials"
	"qmonus.net/adapter/official/pipeline/tasks:dockerLoginGcp"
	"qmonus.net/adapter/official/pipeline/tasks:buiildkitBuildGitConfigSecret"
)

DesignPattern: {
	name: "build:buildkitGcpGitConfigSecret"

	pipelineParameters: {
		image: string | *""
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_buildTask:           string
	_imageFullNameTag:    string
	_imageFullNameDigest: string
	_imageDigest:         string

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
		_imageDigest: {
			utils.#addPrefix
			prefix: _imageName
			key:    "imageDigest"
		}.out
	}
	if pipelineParameters.image == "" {
		_buildTask:           "build"
		_imageFullNameTag:    "imageFullNameTag"
		_imageFullNameDigest: "imageFullNameDigest"
		_imageDigest:         "imageDigest"
	}

	pipelines: {
		build: {
			tasks: {
				"checkout":             gitCheckout.#Builder
				"init-git-credentials": initGitCredentials.#Builder & {
					runAfter: ["checkout"]
				}
				"docker-login-gcp": dockerLoginGcp.#Builder & {
					input: {
						image: _imageName
					}
					runAfter: ["init-git-credentials"]
				}
				"\(_buildTask)": buiildkitBuildGitConfigSecret.#Builder & {
					input: {
						image: _imageName
					}
					runAfter: ["docker-login-gcp"]
				}
			}
			results: {
				"\(_imageFullNameTag)":    tasks["\(_buildTask)"].results.imageFullNameTag
				"\(_imageFullNameDigest)": tasks["\(_buildTask)"].results.imageFullNameDigest
				"\(_imageDigest)":         tasks["\(_buildTask)"].results.imageDigest
			}
		}
	}
}
