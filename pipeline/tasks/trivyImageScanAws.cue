package trivyImageScanAws

import (
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	image:             string | *""
	sbomFormat:        string | *"cyclonedx"
	uploadScanResults: bool | *false
	useSecurityHub:    bool | *false
	shouldNotify:      bool | *false
	resourcePriority:  "high" | *"medium"
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:            "trivy-image-scan-aws"
	input:           #BuildInput
	prefix:          input.image
	prefixAllParams: true

	params: {
		imageName: desc:         "The image name"
		awsCredentialName: desc: "The secret name of AWS credential"
		awsRegion: desc:         "AWS Region"
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
			scanResultsS3BucketName: desc: "The S3 bucket name to store scan results"
		}
		results: {
			uploadedScanResultsUrl: description: "The URL of uploaded scan results"
		}
	}
	if input.useSecurityHub {
		params: {
			awsAccountId: desc: "AWS Account ID"
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

	let scanFindingDir = {
		if prefix != "" {
			"$(workspaces.shared.path)/scan-finding/\(prefix)"
		}
		if prefix == "" {
			"$(workspaces.shared.path)/scan-finding"
		}
	}

	let findingFile = "findings.asff"
	let findingFilePath = "\(scanFindingDir)/\(findingFile)"

	let formattedFindingFile = "formatted-findings.asff"
	let formattedFindingFilePath = "\(scanFindingDir)/\(formattedFindingFile)"

	let overwrittenFindingFile = "overwritten-findings.asff"
	let overwrittenFindingFilePath = "\(scanFindingDir)/\(overwrittenFindingFile)"

	let segmentedFindingDir = "\(scanFindingDir)/segments"

	steps: [{
		name:   "generate-sbom"
		image:  "aquasec/trivy:0.58.1"
		script: """
			set -x
			
			mkdir -p \(scanResultsDir)
			trivy image --format \(input.sbomFormat) --output \(scanResultsDir)/\(sbomFile) $(params.imageName)
			"""
		env: [{
			name:  "AWS_DEFAULT_REGION"
			value: "$(params.awsRegion)"
		}, {
			name:  "AWS_SHARED_CREDENTIALS_FILE"
			value: "/secret/aws/credentials"
		}]
		volumeMounts: [{
			name:      "aws-secret"
			mountPath: "/secret/aws"
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
		name:    "scan-image"
		image:   "aquasec/trivy:0.58.1"
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
		image: "aquasec/trivy:0.58.1"
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
	}, if input.useSecurityHub {
		name:   "scan-image-for-security-hub"
		image:  "aquasec/trivy:0.58.1"
		script: """
			set -x

			mkdir -p \(scanFindingDir)

			# generate scan result as ASFF file
			trivy sbom --no-progress --format template \\
			  --template "@contrib/asff.tpl" \\
			  --output \(findingFilePath) \\
			  --severity CRITICAL,HIGH \\
			  \(scanResultsDir)/\(sbomFile)
			"""
		env: [{
			name:  "AWS_ACCOUNT_ID"
			value: "$(params.awsAccountId)"
		}, {
			name:  "AWS_REGION"
			value: "$(params.awsRegion)"
		}]
		volumeMounts: [{
			name:      "aws-secret"
			mountPath: "/secret/aws"
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
	}, if input.useSecurityHub {
		name:   "process-result-for-security-hub"
		image:  "docker.io/stedolan/jq@sha256:a61ed0bca213081b64be94c5e1b402ea58bc549f457c2682a86704dd55231e09"
		script: """
			#!/bin/bash

			# clean up existing directory
			if [ -d \(segmentedFindingDir) ]; then
				rm -rf \(segmentedFindingDir)
			fi

			mkdir -p \(segmentedFindingDir)

			# extract array of findings from the ASFF file
			cat \(findingFilePath) | jq '.Findings' > \(formattedFindingFilePath)

			# 1. overwrite some attributes with the same image name
			#      to merge results from the same image on Security Hub console
			# 2. overwrite "Id" attribute not to merge results
			#      about the same vulnerability from different images/packages on Security Hub console
			# 3. fill out "Description" attribute if it is empty
			#      to make Security Hub API request successful
			cat \(formattedFindingFilePath) \\
			  | jq '.[].Resources[]?.Id = "$(params.imageName)"' \\
			  | jq '.[].Resources[]?.Details.Container.ImageName |= if . then "$(params.imageName)" else empty end' \\
			  | jq '[ .[] | .Id = "$(params.imageName)" + "/" + .Resources[0].Details.Other["CVE ID"] + "/" + .Resources[0].Details.Other.PkgName ]' \\
			  | jq '.[].Description |= if . == "" then "No description." else . end' \\
			  > \(overwrittenFindingFilePath)

			# count findings
			totalFindings=$(jq 'length' \(overwrittenFindingFilePath))
			echo "Number of findings: $totalFindings"

			if [ $totalFindings -eq 0 ]; then
				echo "SKIP: no findings found"
				exit 0
			fi

			# segment finding file by 100 findings for limitation of Security Hub API
			for ((i = 0, segment = 0; i < totalFindings; i += 100, segment++))
			do
				remainderFindings=$((totalFindings - i))
				if [ $remainderFindings -lt 100 ]; then
					end=$((i + remainderFindings))
				else
					end=$((i + 100))
				fi

				segmentedFindingFile="findings-$segment.asff"
				segmentedFindingFilePath="\(segmentedFindingDir)/$segmentedFindingFile"
				jq ".[$i:$end]" \(overwrittenFindingFilePath) > $segmentedFindingFilePath
			done
			"""
	}, if input.useSecurityHub {
		name:   "send-vulnerability-to-security-hub"
		image:  "amazon/aws-cli:2.22.23"
		script: """
			#!/bin/bash

			if [ -z "$(ls \(segmentedFindingDir))" ]; then
				echo "SKIP: no findings found"
				exit 0
			fi

			while read -r FILE_NAME; do
				aws securityhub batch-import-findings --findings file://\(segmentedFindingDir)/$FILE_NAME
			done < <(ls -tr -1 \(segmentedFindingDir))
			"""
		env: [{
			name:  "AWS_DEFAULT_REGION"
			value: "$(params.awsRegion)"
		}, {
			name:  "AWS_SHARED_CREDENTIALS_FILE"
			value: "/secret/aws/credentials"
		}]
		volumeMounts: [{
			name:      "aws-secret"
			mountPath: "/secret/aws"
			readOnly:  true
		}]
	}, if input.uploadScanResults {
		name:   "upload-scan-result"
		image:  "amazon/aws-cli:2.22.23"
		script: """
			#!/bin/bash

			image_name="$(params.imageName)"
			if [[ "$image_name" == *":"* ]]; then
				converted_path=$(echo "$image_name" | sed 's/:/\\//')
			else
				converted_path="${image_name}/latest"
			fi
			dst="s3://$(params.scanResultsS3BucketName)/${converted_path}/"
			
			aws s3 cp --recursive \(scanResultsDir) ${dst}
			results_url="https://$(params.awsRegion).console.aws.amazon.com/s3/buckets/$(params.scanResultsS3BucketName)?prefix=${converted_path}/"
			echo "Scan result is uploaded to ${results_url}"
			echo ${results_url} > /tekton/results/uploadedScanResultsUrl
			"""
		env: [{
			name:  "AWS_DEFAULT_REGION"
			value: "$(params.awsRegion)"
		}, {
			name:  "AWS_SHARED_CREDENTIALS_FILE"
			value: "/secret/aws/credentials"
		}]
		volumeMounts: [{
			name:      "aws-secret"
			mountPath: "/secret/aws"
			readOnly:  true
		}]
	}, if input.shouldNotify {
		name:   "notice-result"
		image:  "curlimages/curl:8.11.1"
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
