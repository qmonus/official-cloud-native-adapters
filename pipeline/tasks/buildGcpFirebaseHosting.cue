package buildGcpFirebaseHosting

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "build-gcp-firebase-hosting"
	input: #BuildInput

	params: {
		buildTargetDir: {
			desc:    "The path to the frontend build working directory"
			default: "."
		}
	}
	workspaces: [{
		name: "shared"
	}]

	let _envFilePath = "$(workspaces.shared.path)/env/environment_variables.sh"

	steps: [{
		name:  "install-dependencies"
		image: "node:18-alpine3.19"
		command: ["yarn"]
		args: ["install"]
		workingDir: "$(workspaces.shared.path)/source/$(params.buildTargetDir)"
		resources: {
			requests: {
				cpu:    "1"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1"
				memory: "512Mi"
			}
		}
	}, {
		name:       "build"
		image:      "node:18.19.0-bookworm"
		script:     """
			#!/bin/bash
			ENV_FILE_PATH="\(_envFilePath)"
			if [ -e  $ENV_FILE_PATH ]; then
			  echo "set environment variables."
			  source $ENV_FILE_PATH
			fi

			yarn build
			"""
		workingDir: "$(workspaces.shared.path)/source/$(params.buildTargetDir)"
		resources: {
			requests: {
				cpu:    "1"
				memory: "512Mi"
			}
			limits: {
				cpu:    "1"
				memory: "512Mi"
			}
		}
		securityContext: runAsUser: 0
	}]
}
