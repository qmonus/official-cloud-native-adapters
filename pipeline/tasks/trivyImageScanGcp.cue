package trivyImageScanGcp

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
	name:            "trivy-image-scan-gcp"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		imageName: desc:                   "The image name"
		gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential"
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

	_trivyResultJsonFile: string | *"trivy-result.json"
	_trivyResultTxtFile:  string | *"trivy-result.txt"
	if prefix != "" {
		_trivyResultJsonFile: "\(prefix)-trivy-result.json"
		_trivyResultTxtFile:  "\(prefix)-trivy-result.txt"
	}

	steps: [{
		name:    "image-scan"
		image:   "aquasec/trivy:0.50.4"
		onError: "continue"
		script:  """
			set -x
			
			mkdir -p $(workspaces.shared.path)/scan-results

			trivy image --no-progress --format json \\
			  --output $(workspaces.shared.path)/scan-results/\(_trivyResultJsonFile) \\
			  --severity $(params.severity) --exit-code 1 $(params.imageName) \\
			  $(params.extraImageScanOptions)
			"""
		env: [{
			name:  "GOOGLE_APPLICATION_CREDENTIALS"
			value: "/secret/account.json"
		}]
		volumeMounts: [{
			name:      "user-gcp-secret"
			mountPath: "/secret"
			readOnly:  true
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
			"$(workspaces.shared.path)/scan-results/\(_trivyResultTxtFile)",
			"$(workspaces.shared.path)/scan-results/\(_trivyResultJsonFile)",
		]
	}, {
		name:   "dump-result"
		image:  "bash:5.2"
		script: """
			cat $(workspaces.shared.path)/scan-results/\(_trivyResultTxtFile)
			"""
	}, if input.shouldNotify {
		name:   "notice-result"
		image:  "curlimages/curl:8.6.0"
		script: """
			#!/bin/sh
			set -o nounset
			set -o xtrace
			set -o pipefail

			grep -q '"Vulnerabilities": \\[' $(workspaces.shared.path)/scan-results/\(_trivyResultJsonFile)
			if [ $? -eq 1 ]; then
			  echo "No vulnerabilities were found."
			  exit 0
			fi

			# extract target name and number of vulnerabilities
			results=$(cat $(workspaces.shared.path)/scan-results/\(_trivyResultTxtFile) | grep -B 2 "^Total")
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
		name:   "validate-scan-result"
		image:  "docker.io/stedolan/jq@sha256:a61ed0bca213081b64be94c5e1b402ea58bc549f457c2682a86704dd55231e09"
		script: """
			#!/bin/bash
			
			vulnExists=$(jq '[.Results[] | if .Vulnerabilities then 1 else 0 end] | add' "$(workspaces.shared.path)/scan-results/\(_trivyResultJsonFile)")
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
