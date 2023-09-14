package acrImagePromote

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
		azServicePrincipalSecretName: desc: "The secret name of Azure service principal credential"
		imageNameFrom: desc:                "Full name of the image to promote from"
		imageRegistryPath: desc:            "Path of the container registry without image name"
		containerRegistry: desc:            "Container registry endpoint"
		imageShortName: desc:               "Short name of the image"
		imageTag: desc:                     "Image tag"
		azureTenantId: desc:                "Azure tenant ID"
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
		image: "mcr.microsoft.com/azure-cli:2.9.1"
		script: """
			#!/bin/bash
			set -o nounset
			set -e
			set +x
			az login --service-principal --username ${APP_ID} --password ${PASSWORD} --tenant $(params.azureTenantId)
			# Remove duplicates between `imageRegistryPath` and `containerRegistry`
			imageDirectoryPath=$(echo $(params.imageRegistryPath)/ | sed "s|$(params.containerRegistry)/||g");
			az acr import --name $(params.containerRegistry) --image ${imageDirectoryPath}$(params.imageShortName):$(params.imageTag) --source $(params.imageNameFrom) --username ${APP_ID} --password ${PASSWORD} --force
			"""
		env: [{
			name: "APP_ID"
			valueFrom: {
				secretKeyRef: {
					name: "$(params.azServicePrincipalSecretName)"
					key:  "appId"
				}
			}
		}, {
			name: "PASSWORD"
			valueFrom: {
				secretKeyRef: {
					name: "$(params.azServicePrincipalSecretName)"
					key:  "password"
				}
			}
		}]
	}, {
		name:  "resolve-digest"
		image: "mcr.microsoft.com/azure-cli:2.9.1"
		script: """
			#!/bin/bash
			set -o nounset
			set -e
			set +x
			# Remove duplicates between `imageRegistryPath` and `containerRegistry`
			imageDirectoryPath=$(echo $(params.imageRegistryPath)/ | sed "s|$(params.containerRegistry)/||g");
			az acr repository show -n $(params.containerRegistry) --image ${imageDirectoryPath}$(params.imageShortName):$(params.imageTag) --username ${APP_ID} --password ${PASSWORD} \\
			| jq -r '.digest' \\
			| tee /tekton/results/imageDigest
			"""
		env: [{
			name: "APP_ID"
			valueFrom: {
				secretKeyRef: {
					name: "$(params.azServicePrincipalSecretName)"
					key:  "appId"
				}
			}
		}, {
			name: "PASSWORD"
			valueFrom: {
				secretKeyRef: {
					name: "$(params.azServicePrincipalSecretName)"
					key:  "password"
				}
			}
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
}
