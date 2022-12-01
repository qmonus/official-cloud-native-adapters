package buildkitGcpGitConfigSecret

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:initGitCredentials"
	"qmonus.net/adapter/official/pipeline/tasks:dockerLoginGcp"
	"qmonus.net/adapter/official/pipeline/tasks:buildkitBuildGitConfigSecret"
)

DesignPattern: {
	name: "build:buildkitGcpGitConfigSecret"

	pipelineParameters: {
		image:          string | *""
		repositoryKind: string | *""
	}

	let _imageName = strings.ToLower(pipelineParameters.image)

	_buildTask:           string
	_loginTask:           string
	_imageFullNameTag:    string
	_imageFullNameDigest: string
	_imageDigest:         string

	if pipelineParameters.image != "" {
		_buildTask: {
			utils.#concatKebab
			input: [_imageName, "build"]
		}.out
		_loginTask: {
			utils.#concatKebab
			input: [_imageName, "docker-login-gcp"]
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
		_loginTask:           "docker-login-gcp"
		_imageFullNameTag:    "imageFullNameTag"
		_imageFullNameDigest: "imageFullNameDigest"
		_imageDigest:         "imageDigest"
	}

	pipelines: {
		build: {
			tasks: {
				"checkout": {
					let _repositoryKind = pipelineParameters.repositoryKind
					gitCheckout.#Builder & {
						input: {
							repositoryKind: _repositoryKind
						}
					}
				}
				"init-git-credentials": {
					let _repositoryKind = pipelineParameters.repositoryKind
					initGitCredentials.#Builder & {
						runAfter: ["checkout"]
						input: {
							repositoryKind: _repositoryKind
						}
					}
				}
				"\(_loginTask)": dockerLoginGcp.#Builder & {
					input: {
						image: _imageName
					}
					runAfter: ["init-git-credentials"]
				}
				"\(_buildTask)": buildkitBuildGitConfigSecret.#Builder & {
					input: {
						image: _imageName
					}
					runAfter: ["\(_loginTask)"]
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
