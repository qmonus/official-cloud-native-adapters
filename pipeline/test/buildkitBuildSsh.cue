package buildkitBuildSsh

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
		gitCheckoutSubDirectory: desc: "Path in the source directory to clone Git repository"
		cacheImageName: desc: "Name of the cache image"
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
		secretNameSshKey: {
			desc: "secretNameSshKey"
		}
		sshUserName: {
			desc: "sshUserName"
		}
		sshHost: {
			desc: "sshHost"
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
			value: "$(workspaces.shared.path)/$(params.gitCheckoutSubDirectory)/dockerconfig"
		}, {
			name:  "BUILDCTL_CONNECT_RETRIES_MAX"
			value: "20"
			},{
				name: "http_proxy"
				value: "socks5://127.0.0.1:9080"
			},{
				name: "https_proxy"
				value: "socks5://127.0.0.1:9080"
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
			--local context=$(params.gitCheckoutSubDirectory)/$(params.pathToContext) \\
			--local dockerfile=$(params.gitCheckoutSubDirectory)/$(params.pathToContext) \\
			--output type=image,name=$(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag),push=true \\
			--import-cache type=registry,ref=$(params.cacheImageName):buildcache \\
			--export-cache type=registry,ref=$(params.cacheImageName):buildcache \\
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

	sidecars: [{
		name:  "ssh-tunnel"
		image: "asia.gcr.io/axis-gcp-dev-46876560/ssh-client:test"
		args: [
			"-o",
			"StrictHostKeyChecking=no",
			"-i",
			"/secret/identity_file",
			"-D",
			"9080",
			"-4",
			"$(params.sshUserName)@$(params.sshHost)",
			"-vv",
			"-N",
		]
		command: [
			"ssh",
		]
		volumeMounts: [{
			name:      "ssh-key"
			mountPath: "/secret"
		}]
	}]

	volumes: [{
		name: "ssh-key"
		secret: {
			items: [{
				key:  "identity_file"
				path: "identity_file"
			}]
			secretName:  "$(params.secretNameSshKey)"
			defaultMode: 384
		}
	}]
}
