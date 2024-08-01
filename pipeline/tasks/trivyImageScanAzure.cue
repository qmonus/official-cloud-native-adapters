package trivyImageScanAzure

import (
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	image:             string | *""
	sbomFormat:        string | *"cyclonedx"
	uploadScanResults: bool | *false
	shouldNotify:      bool | *false
	resourcePriority:  "high" | *"medium"
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
		azureSubscriptionId: desc:   "Azure Subscription ID"
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
	if input.uploadScanResults {
		params: {
			scanResultsBlobStorageContainerName: desc: "The Azure Blob Storage Container Name to store scan results"
			azureStorageAccountName: desc:             "Azure Storage Account Name"
		}
		results: {
			uploadedScanResultsUrl: description: "The URL of uploaded scan results"
		}
	}
	workspaces: [{
		name: "shared"
	}]

	let scanResultsDir = {
		if prefix != "" {
			"$(workspaces.shared.path)/scan-results/\(prefix)"
		}
		if prefix == "" {
			"$(workspaces.shared.path)/scan-results"
		}
	}

	let sbomFile = {
		if input.sbomFormat == "cyclonedx" {
			"sbom-cyclonedx.json"
		}
		if input.sbomFormat == "spdx" {
			"sbom.spdx"
		}
		if input.sbomFormat == "spdx-json" {
			"sbom-spdx.json"
		}
	}

	let trivyResultJsonFile = "trivy-result.json"

	let trivyResultTxtFile = "trivy-result.txt"

	steps: [{
		name:   "generate-sbom"
		image:  "aquasec/trivy:0.50.4"
		script: """
			set -x
			
			mkdir -p \(scanResultsDir)
			trivy image --format \(input.sbomFormat) --output \(scanResultsDir)/\(sbomFile) $(params.imageName)
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
		name:    "scan-image"
		image:   "aquasec/trivy:0.50.4"
		onError: "continue"
		script:  """
			set -x
			
			trivy sbom --no-progress --format json \\
			  --output \(scanResultsDir)/\(trivyResultJsonFile) \\
			  --severity $(params.severity) --exit-code 1 \\
			  \(scanResultsDir)/\(sbomFile) \\
			  $(params.extraImageScanOptions)
			"""
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
			"\(scanResultsDir)/\(trivyResultTxtFile)",
			"\(scanResultsDir)/\(trivyResultJsonFile)",
		]
	}, {
		name:   "dump-result"
		image:  "bash:5.2"
		script: """
			cat \(scanResultsDir)/\(trivyResultTxtFile)
			"""
	}, if input.uploadScanResults {
		name:   "upload-scan-result"
		image:  "mcr.microsoft.com/azure-cli:2.51.0"
		script: """
			#!/bin/bash
			image_name="$(params.imageName)"
			if [[ "$image_name" == *":"* ]]; then
				converted_path=$(echo "$image_name" | sed 's/:/\\//')
			else
				converted_path="${image_name}/latest"
			fi

			az login --service-principal -u ${AZURE_CLIENT_ID} -p ${AZURE_CLIENT_SECRET} --tenant ${AZURE_TENANT_ID} > /dev/null
			az storage blob upload-batch -s \(scanResultsDir) -d $(params.scanResultsBlobStorageContainerName)/${converted_path} --account-name ${AZURE_STORAGE_ACCOUNT_NAME} --overwrite
			
			storage_account_id=$(az storage account show --name ${AZURE_STORAGE_ACCOUNT_NAME} --query id --output tsv)
			encoded_storage_account_id=$(echo "$storage_account_id" | sed 's/\\//%2F/g')
			results_url="https://portal.azure.com/#view/Microsoft_Azure_Storage/ContainerMenuBlade/~/overview/storageAccountId/${encoded_storage_account_id}/path/$(params.scanResultsBlobStorageContainerName)/${converted_path}"
			echo "Scan result is uploaded to ${results_url}"
			echo ${results_url} > /tekton/results/uploadedScanResultsUrl
			"""
		env: [{
			name:  "AZURE_TENANT_ID"
			value: "$(params.azureTenantId)"
		}, {
			name:  "AZURE_SUBSCRIPTION_ID"
			value: "$(params.azureSubscriptionId)"
		}, {
			name:  "AZURE_CLIENT_ID"
			value: "$(params.azureApplicationId)"
		}, {
			name: "AZURE_CLIENT_SECRET"
			valueFrom: secretKeyRef: {
				name: "$(params.azureClientSecretName)"
				key:  "password"
			}
		}, {
			name:  "AZURE_STORAGE_ACCOUNT_NAME"
			value: "$(params.azureStorageAccountName)"
		}]
	},
		if input.shouldNotify {
			name:   "notice-result"
			image:  "curlimages/curl:8.6.0"
			script: """
				#!/bin/sh
				set -o nounset
				set -o xtrace
				set -o pipefail

				grep -q '"Vulnerabilities": \\[' \(scanResultsDir)/\(trivyResultJsonFile)
				if [ $? -eq 1 ]; then
				  echo "No vulnerabilities were found."
				  exit 0
				fi

				# extract target name and number of vulnerabilities
				results=$(cat \(scanResultsDir)/\(trivyResultTxtFile) | grep -B 2 "^Total")
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

				vulnExists=$(jq '[.Results[] | if .Vulnerabilities then 1 else 0 end] | add' "\(scanResultsDir)/\(trivyResultJsonFile)")
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
