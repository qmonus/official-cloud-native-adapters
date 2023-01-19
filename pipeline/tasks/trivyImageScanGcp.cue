package trivyImageScanGcp

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
	name:            "trivy-image-scan"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		imageName: desc:                   "The image name"
		gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential"
	}

	steps: [{
		name:  "image-scan"
		image: "aquasec/trivy:0.36.1"
		args: [
			"image",
			"--no-progress",
			"$(params.imageName)",
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
