package buildkitBuild_nocache

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	image: string | *""
	extraArgs: {[string]: string}
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:            "buildkit"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		dockerfile: {
			desc:    "The path to the dockerfile to build (relative to the context)"
			default: "Dockerfile"
		}
		imageRegistryPath: desc: "Path of the container registry without image name"
		imageShortName: desc:    "Short name of the image"
		imageTag: desc:          "Image tag"
		pathToContext: {
			desc:    "The path to the build working directory"
			default: "."
		}
		extraArgs: {
			desc:    "Buildkit additional options"
			default: ""
		}
	}
	results: {
		imageFullNameTag: {
			description: "Full name of the image with its tag"
		}
		imageFullNameDigest: {
			description: "Full name of the image with its SHA digest"
		}
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		env: [{
			name:  "DOCKER_CONFIG"
			value: "$(workspaces.shared.path)/dockerconfig"
		}, {
			name:  "BUILDCTL_CONNECT_RETRIES_MAX"
			value: "20"
		}]
		image: "moby/buildkit:v0.9.2"
		name:  "build-and-push"
		script: """
			buildctl-daemonless.sh --debug \\
			build \\
			--progress=plain \\
			--frontend=dockerfile.v0 \\
			--opt filename=$(params.dockerfile) \\
			--frontend=dockerfile.v0 \\
			--local context=$(params.pathToContext) \\
			--local dockerfile=$(params.pathToContext) \\
			--output type=image,name=$(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag),push=true \\
			--metadata-file $(workspaces.shared.path)/meta.json \\
			$(params.extraArgs)
			"""

		securityContext: privileged: true
		workingDir: "$(workspaces.shared.path)/source"
	}, {
		image: "docker.io/stedolan/jq@sha256:a61ed0bca213081b64be94c5e1b402ea58bc549f457c2682a86704dd55231e09"
		name:  "resolve-digest"
		script: """
			jq -rj ' .[\"containerimage.digest\"]' \\
			  < $(workspaces.shared.path)/meta.json \\
			  | tee /tekton/results/imageFullNameDigest

			"""
	}, {
		name:  "dump-result"
		image: "bash:latest"
		script: """
			#!/usr/bin/env bash
			echo -n $(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag) | tee /tekton/results/imageFullNameTag
			"""
	}]
}
