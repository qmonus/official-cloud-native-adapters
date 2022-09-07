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
		containerRegistry: {
			desc: ""
		}
		// FIXME: Remove this param
		gitCheckoutSubDirectory: {
			desc: "Path in the source directory to clone Git repository"
		}
		azServicePrincipalSecretName: {
			desc: ""
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
			"docker --config=$(workspaces.shared.path)/$(params.gitCheckoutSubDirectory)/dockerconfig login $(params.containerRegistry) --username $(APP_ID) --password '$(PASSWORD)'",
		]
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
	}]
}
