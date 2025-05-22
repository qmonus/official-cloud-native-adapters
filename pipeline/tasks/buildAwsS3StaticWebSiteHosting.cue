package buildAwsS3StaticWebSiteHosting

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "build-aws-static-website"
	input: #BuildInput

	params: {
		buildTargetDir: {
			desc:    "The path to the frontend build working directory"
			default: "."
		}
		buildOptions: {
			desc:    "The build options for the frontend"
			default: ""
		}
		packageManagerName: {
			desc:    "The package manager to use for the build"
			default: "yarn"
		}
	}
	workspaces: [{
		name: "shared"
	}]

	let _envFilePath = "$(workspaces.shared.path)/env/environment_variables.sh"

	steps: [{
		name:  "install-dependencies"
		image: "node:18-alpine3.19"
		command: ["$(params.packageManagerName)"]
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
			if [ $(params.packageManagerName) = "npm" ]; then
			  echo "npm is used as package manager."
			  npm run build $(params.buildOptions)
			elif [ $(params.packageManagerName) = "yarn" ]; then
			  echo "yarn is used as package manager."
			  yarn build $(params.buildOptions)
			else
			  echo "unsupported package manager: $(params.packageManagerName)"
			  exit 1
			fi
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
