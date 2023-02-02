package gcraneImagePromote

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	image: string | *""
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:            "image-promote"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential"
		imageNameFrom: desc:               "Full name of the image to promote from"
		imageRegistryPath: desc:           "Path of the container registry without image name"
		imageShortName: desc:              "Short name of the image"
		imageTag: desc:                    "Image tag"
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
		name:  "image-promote"
		image: "gcr.io/go-containerregistry/gcrane:v0.12.1"
		args: [
			"cp",
			"--",
			"$(params.imageNameFrom)",
			"$(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag)",
		]
		env: [{
			name:  "GOOGLE_APPLICATION_CREDENTIALS"
			value: "/secret/account.json"
		}]
		volumeMounts: [{
			name:      "user-gcp-secret"
			mountPath: "/secret"
			readOnly:  true
		}]
	}, {
		name:  "resolve-digest"
		image: "gcr.io/go-containerregistry/gcrane:debug"
		script: """
			#!/busybox/sh -x
			set -o nounset
			set -o xtrace
			gcrane digest $(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag) \\
			| tee /tekton/results/imageDigest
			"""
		env: [{
			name:  "GOOGLE_APPLICATION_CREDENTIALS"
			value: "/secret/account.json"
		}]
		volumeMounts: [{
			name:      "user-gcp-secret"
			mountPath: "/secret"
			readOnly:  true
		}]
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
