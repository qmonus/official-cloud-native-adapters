package buildkitBuildGitConfigSecret

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
	name:            "buildkit-git-config-secret"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	let _cacheImageName = "$(params.imageRegistryPath)/$(params.imageShortName)"

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
		imageDigest: {
			description: "SHA digest of the image"
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
		image:  "moby/buildkit:v0.12.5"
		name:   "build-and-push"
		script: """
			if [ "$(params.imageTag)" = "buildcache" ]; then
			  echo "Error: unsupported imageTag is specified."
			  exit 1
			fi

			buildctl-daemonless.sh \\
			build \\
			--progress=plain \\
			--frontend=dockerfile.v0 \\
			--opt filename=$(params.dockerfile) \\
			--frontend=dockerfile.v0 \\
			--local context=$(params.pathToContext) \\
			--local dockerfile=$(params.pathToContext) \\
			--output type=image,name=$(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag),push=true \\
			--import-cache type=registry,ref=\(_cacheImageName):buildcache \\
			--export-cache type=registry,ref=\(_cacheImageName):buildcache \\
			--metadata-file $(workspaces.shared.path)/meta.json \\
			--secret id=gitconfig,src=$(workspaces.shared.path)/.gitconfig \\
			$(params.extraArgs)
			"""

		securityContext: privileged: true
		workingDir: "$(workspaces.shared.path)/source"
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
		image: "docker.io/stedolan/jq@sha256:a61ed0bca213081b64be94c5e1b402ea58bc549f457c2682a86704dd55231e09"
		name:  "resolve-digest"
		script: """
			jq -rj ' .[\"containerimage.digest\"]' \\
			  < $(workspaces.shared.path)/meta.json \\
			  | tee /tekton/results/imageDigest

			"""
	}, {
		name:  "dump-imagefullnametag"
		image: "bash:latest"
		script: """
			#!/usr/bin/env bash
			echo -n $(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag) | tee /tekton/results/imageFullNameTag
			"""
	}, {
		name:  "dump-imagefullnamedigest"
		image: "bash:latest"
		script: """
			#!/usr/bin/env bash
			cat <(echo -n $(params.imageRegistryPath)/$(params.imageShortName)@) /tekton/results/imageDigest | tee /tekton/results/imageFullNameDigest
			"""
	}]
}
