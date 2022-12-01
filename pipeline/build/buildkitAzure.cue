package buildkitAzure

import (
	"strings"
	"qmonus.net/adapter/official/pipeline:utils"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:dockerLoginAzure"
	"qmonus.net/adapter/official/pipeline/tasks:buildkitBuild"
)

DesignPattern: {
	name: "build:buildkit"

	pipelineParameters: {
		image:          string | *""
		repositoryKind: string | *""
		useSshKey:      bool | *false
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
			input: [_imageName, "docker-login-azure"]
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
		_loginTask:           "docker-login-azure"
		_imageFullNameTag:    "imageFullNameTag"
		_imageFullNameDigest: "imageFullNameDigest"
		_imageDigest:         "imageDigest"
	}

	pipelines: {
		build: {
			tasks: {
				"checkout": {
					let _repositoryKind = pipelineParameters.repositoryKind
					let _useSshKey = pipelineParameters.useSshKey

					if _repositoryKind == "bitbucket" {
						gitCheckoutSsh.#Builder & {
							input: {
								repositoryKind: _repositoryKind
							}
						}
					}

					if _repositoryKind != "bitbucket" {
						if _useSshKey {
							gitCheckoutSsh.#Builder & {
								input: {
									repositoryKind: _repositoryKind
								}
							}
						}
						if !_useSshKey {
							gitCheckout.#Builder & {
								input: {
									repositoryKind: _repositoryKind
								}
							}
						}
					}
				}
				"\(_loginTask)": dockerLoginAzure.#Builder & {
					input: {
						image: _imageName
					}
					runAfter: ["checkout"]
				}
				"\(_buildTask)": buildkitBuild.#Builder & {
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
