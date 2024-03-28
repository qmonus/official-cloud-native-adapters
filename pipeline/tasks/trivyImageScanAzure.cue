package trivyImageScanAzure

import (
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	image:            string | *""
	shouldNotify:     bool | *false
	resourcePriority: "high" | *"medium"
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:            "trivy-image-scan-azure"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		imageName: desc:             "The image name"
		azureTenantId: desc:         "Azure Tenant ID"
		azureApplicationId: desc:    "Azure Application ID"
		azureClientSecretName: desc: "Credential Name of Azure Client Secret"
		mentionTarget: {
			desc:    "mention target of Slack"
			default: ""
		}
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		name:  "image-scan"
		image: "aquasec/trivy:0.49.1"
		args: [
			"image",
			"--no-progress",
			"--output",
			"$(workspaces.shared.path)/trivy-result.txt",
			"$(params.imageName)",
		]
		env: [{
			name:  "AZURE_TENANT_ID"
			value: "$(params.azureTenantId)"
		}, {
			name:  "AZURE_CLIENT_ID"
			value: "$(params.azureApplicationId)"
		}, {
			name: "AZURE_CLIENT_SECRET"
			valueFrom: {
				secretKeyRef: {
					name: "$(params.azureClientSecretName)"
					key:  "password"
				}
			}
		}]
		resources: {
			if input.resourcePriority == "medium" {
				requests: {
					cpu:    "0.5"
					memory: "512Mi"
				}
				limits: {
					cpu:    "0.5"
					memory: "512Mi"
				}
			}
			if input.resourcePriority == "high" {
				requests: {
					cpu:    "1"
					memory: "1Gi"
				}
				limits: {
					cpu:    "1"
					memory: "1Gi"
				}
			}
		}
	}, {
		name:  "dump-result"
		image: "bash:latest"
		script: """
				cat $(workspaces.shared.path)/trivy-result.txt
			"""
	},
		if input.shouldNotify {
			name:  "notice-result"
			image: "curlimages/curl:8.6.0"
			script: """
				#!/bin/sh
				set -o nounset
				set -o xtrace
				set -o pipefail

				# extract target name and number of vulnerabilities
				results=$(cat $(workspaces.shared.path)/trivy-result.txt | grep -B 2 "^Total")
				if  [ $? -eq 1 ]; then
				  echo "No vulnerabilities were found."
				  exit 0
				fi
				# remove separator and decorate results
				results=$(echo "${results}" | sed '/^=/d' | sed 's/\\(^Total.*$\\)/\\*\\1\\*/' | sed ':l; N; s/\\n/\\\\n/; b l;')
				if [ -z "$(params.mentionTarget)" ]; then
				  message=":x: *Image scan completed.*\\n${results}"
				else
				  message="$(params.mentionTarget)\\n:x: *Image scan completed.*\\n${results}"
				fi
				curl -s -X POST -H "Content-Type: application/json" -d "{\\"message\\":\\"${message}\\", \\"severity\\":\\"Warn\\"}" \\
				  ${VS_API_ENDPOINT}/apis/v1/projects/$(context.taskRun.namespace)/taskruns/$(context.taskRun.name)/notification?taskrun_uid=$(context.taskRun.uid)
				"""
			env: [
				{
					name: "VS_API_ENDPOINT"
					valueFrom: fieldRef: fieldPath: "metadata.annotations['\(base.config.vsApiEndpointKey)']"
				},
			]
		},
	]
}
