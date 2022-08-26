package authregist

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	image: string | *""
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:            "auth-google-registry"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		gcpServiceAccountSecretName: {
			desc: "The secret name of GCP SA credential"
		}
		gcpProjectId: {
			desc: ""
		}
		containerRegistry: {
			desc:    ""
			default: ""
		}
		gitCheckoutSubDirectory: {
			desc: "Path in the source directory to clone Git repository"
		}
	}

	results: {
		dockerconfigPath: description: "Path of dockerconfig"
	}

	workspaces: [{
		name: "shared"
	}]

	steps: [{
		name:  "gcloud-get-registory-credentials"
		image: "google/cloud-sdk:278.0.0-alpine"
		command: [
			"/bin/sh",
			"-c",
		]
		args: [
			"gcloud auth activate-service-account --key-file=$(GOOGLE_APPLICATION_CREDENTIALS) --project=$(params.gcpProjectId) && gcloud auth print-access-token > /workspace/.gar-cred.txt",
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
		name:  "docker-login"
		image: "docker"
		command: [
			"/bin/sh",
			"-c",
		]
		args: [
			"docker --config=$(workspaces.shared.path)/$(params.gitCheckoutSubDirectory)/dockerconfig login -u oauth2accesstoken -p \"$(cat /workspace/.gar-cred.txt)\" $(params.containerRegistry)",
		]
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
