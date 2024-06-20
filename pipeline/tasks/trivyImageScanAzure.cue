package trivyImageScanAzure

import (
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	image:            string | *""
	shouldNotify:     bool | *false
	resourcePriority: "high" | *"medium"
	extraImageScanOptions: {[string]: string}
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
		severity: {
			desc:    "The severity of vulnerabilities to be scanned"
			default: "CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN"
		}
		ignoreVulnerability: {
			desc:    "Ignore the vulnerability scan result"
			default: "false"
		}
		mentionTarget: {
			desc:    "mention target of Slack"
			default: ""
		}
		extraImageScanOptions: {
			desc:    "Extra arguments for trivy image command"
			default: ""
		}
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		name:    "image-scan"
		image:   "aquasec/trivy:0.50.4"
		onError: "continue"
		script: """
			set -x
			trivy image --no-progress --output $(workspaces.shared.path)/trivy-result.json --format json \\
			  --severity $(params.severity) --exit-code 1 $(params.imageName) \\
			  $(params.extraImageScanOptions)
			"""
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
		name:  "convert-result-to-table"
		image: "aquasec/trivy:0.50.4"
		args: [
			"convert",
			"--format",
			"table",
			"--output",
			"$(workspaces.shared.path)/trivy-result.txt",
			"$(workspaces.shared.path)/trivy-result.json",
		]
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

				grep -q '"Vulnerabilities": \\[' $(workspaces.shared.path)/trivy-result.json
				if [ $? -eq 1 ]; then
				  echo "No vulnerabilities were found."
				  exit 0
				fi

				# extract target name and number of vulnerabilities
				results=$(cat $(workspaces.shared.path)/trivy-result.txt | grep -B 2 "^Total")
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
		}, {
			name:  "validate-scan-result"
			image: "docker.io/stedolan/jq@sha256:a61ed0bca213081b64be94c5e1b402ea58bc549f457c2682a86704dd55231e09"
			script: """
				vulnExists=$(jq '[.Results[] | if .Vulnerabilities then 1 else 0 end] | add' "$(workspaces.shared.path)/trivy-result.json")
				if [ $vulnExists -eq 0 ]; then
					echo "No vulnerabilities were found."
					exit 0
				fi

				if [ "$(params.ignoreVulnerability)" == "true" ]; then
					echo "Vulnerabilities were found but ignore the scan result."
					exit 0
				fi

				echo "Vulnerabilities were found."
				exit 1
				"""
		},
	]
}
