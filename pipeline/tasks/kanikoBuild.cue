package kanikoBuild

import (
	"list"
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	image:        string | *""
	pathToSource: string | *""
	// The parameters definition for ARGs of Dockerfile
	buildArgs: [string]: {
		name:    string
		default: string
	}
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "kaniko-build-push"

	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	_sortedBuildArgs: list.Sort([ for k, e in input.buildArgs {e}], {x: {}, y: {}, less: x.name < y.name})

	// TODO kanikobuild specificなものと、generalなものに分ける
	params: {
		pathToDockerFile: {
			desc:    "The path to the dockerfile to build (relative to the context)"
			default: "Dockerfile"
		}
		pathToContext: {
			desc:    "The path to the build context"
			default: "."
		}
		imageShortName: {
			desc:    "The Short name of the image"
			default: ""
		}
		imageTag: {
			desc:    "The tag name of container"
			default: "latest"
		}
		gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential"
		imageRegistryPath: desc:           "Path of the container registry without image name"

		kanikoOptions: {
			desc:    "Additional parameters for Kaniko"
			default: ""
		}
		{
			for _, sortedValue in _sortedBuildArgs {
				for k, v in input.buildArgs {
					if v.name == sortedValue.name {
						"\(v.name)": {
							desc:    "Build Argument to pass in ARG \(k) in Dockerfile"
							default: "\(v.default)"
						}
					}
				}
			}
		}
	}
	workspaces: [{
		name: "shared"
	}]

	results: {
		imageFullNameTag: {
			description: "Full name of the image with its tag"
		}
		imageFullNameDigest: {
			description: "Full name of the image with its SHA digest"
		}
	}

	steps: [{
		name:  "build-and-push"
		image: "gcr.io/kaniko-project/executor:debug"
		args:  list.Concat([
			[
				"--dockerfile=$(params.pathToDockerFile)",
				"--destination=$(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag)",
				"--context=$(params.pathToContext)",
				"--image-name-with-digest-file=/tekton/results/imageFullNameDigest",
			],
			[
				for _, sortedValue in _sortedBuildArgs {
					for k, v in input.buildArgs {
						if v.name == sortedValue.name {
							"--build-arg=\(k)=$(params.\(v.name))"
						}
					}
				},
			],
		])
		env: [{
			name:  "GOOGLE_APPLICATION_CREDENTIALS"
			value: "/secret/account.json"
		}]
		script: """
			#!/busybox/sh -x
			set -o nounset
			set -o xtrace
			extraparams=$(awk -v arg="$(params.kanikoOptions)" '
			  BEGIN {
			    n=split(arg, params,  "," )
			    for (i=1; i<=n; i++) {
			      v = params[i]
			      gsub("^ +", "", v); gsub(" +$", "", v);
			      prefix = substr(v, 1, 2)
			      if (prefix == "--") {
			        print(v)
			      }
			    }
			  }'
			)
			/kaniko/executor $@ ${extraparams}
			"""

		volumeMounts: [{
			mountPath: "/secret"
			name:      "user-gcp-secret"
		}]
		workingDir: "$(workspaces.shared.path)/source/\(input.pathToSource)"
		resources: {
			requests: {
				cpu:    "2"
				memory: "5Gi"
			}
			limits: {
				cpu:    "2"
				memory: "5Gi"
			}
		}
	}, {
		name:  "dump-result"
		image: "bash:latest"
		script: """
			#!/usr/bin/env bash
			echo -n $(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag) | tee /tekton/results/imageFullNameTag
			"""
	}]

	volumes: [{
		name: "user-gcp-secret"
		secret: {
			items: [{
				key:  "serviceaccount"
				path: "account.json"
			}]
			secretName: "$(params.gcpServiceAccountSecretName)"
		}
	}]
}
