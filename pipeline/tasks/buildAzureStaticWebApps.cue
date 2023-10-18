package buildAzureStaticWebApps

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "build-azure-static-web-apps"
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

	steps: [{
		name:  "install-dependencies"
		image: "node:18-alpine3.17"
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
		name:  "build"
		image: "swacli/static-web-apps-cli:1.1.4"
		command: ["swa"]
		args: ["build", "--auto"]
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
