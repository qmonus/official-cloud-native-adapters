package dockerLoginAzure

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	image: string | *""
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:            "docker-login-azure"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		imageRegistryPath: {
			desc: "Path of the container registry without image name"
		}
		// FIXME: Remove this param
		gitCheckoutSubDirectory: {
			desc: "Path in the source directory to clone Git repository"
		}
		azureApplicationId: {
			desc: "Azure Application ID"
		}
		azureClientSecretName: {
			desc: "Credential Name of Azure Client Secret"
		}
	}

	workspaces: [{
		name: "shared"
	}]

	steps: [{
		name:  "docker-login"
		image: "docker"
		command: [
			"/bin/sh",
			"-c",
		]
		args: [
			"docker --config=$(workspaces.shared.path)/$(params.gitCheckoutSubDirectory)/dockerconfig login $(params.imageRegistryPath) --username $(ARM_CLIENT_ID) --password '$(ARM_CLIENT_SECRET)'",
		]
		env: [{
			name:  "ARM_CLIENT_ID"
			value: "$(params.azureApplicationId)"
		}, {
			name: "ARM_CLIENT_SECRET"
			valueFrom: {
				secretKeyRef: {
					name: "$(params.azureClientSecretName)"
					key:  "password"
				}
			}
		}]
	}]
}
