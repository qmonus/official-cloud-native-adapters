package dockerLoginAws

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	image: string | *""
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:            "docker-login-aws"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		awsCredentialName: {
			desc: "The secret name of AWS credential"
		}
		awsProfile: {
			desc:    ""
			default: "default"
		}
		awsRegion: {
			desc: ""
		}
		containerRegistry: {
			desc: ""
		}
		// FIXME: Remove this param
		gitCheckoutSubDirectory: {
			desc: "Path in the source directory to clone Git repository"
		}
	}

	workspaces: [{
		name: "shared"
	}]

	steps: [{
		name:  "aws-get-registory-credentials"
		image: "amazon/aws-cli:2.12.1"
		command: [
			"/bin/sh",
			"-c",
		]
		args: [
			"aws ecr get-login-password --profile $(params.awsProfile) --region $(params.awsRegion)  > $(workspaces.shared.path)/.ecr-credentials.txt",
		]
		env: [{
			name:  "AWS_SHARED_CREDENTIALS_FILE"
			value: "/secret/aws/credentials"
		}]
		volumeMounts: [{
			name:      "aws-secret"
			mountPath: "/secret/aws"
			readOnly:  true
		}]
	}, {
		name:  "docker-login"
		image: "docker"
		command: [
			"/bin/sh",
			"-c",
		]
		args: [
			"cat $(workspaces.shared.path)/.ecr-credentials.txt | docker --config=$(workspaces.shared.path)/$(params.gitCheckoutSubDirectory)/dockerconfig login --password-stdin --username AWS $(params.containerRegistry)",
		]
	}]
	volumes: [{
		name: "aws-secret"
		secret: {
			items: [{
				key:  "credentials"
				path: "credentials"
			}]
			secretName: "$(params.awsCredentialName)"
		}
	}]
}
