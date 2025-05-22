package deployAwsS3StaticWebSiteHosting

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "deploy-aws-static-website"
	input: #BuildInput
	results:
		uploadedBucketUrl: {
			description: "The URL of the S3 bucket where the file was uploaded"
		}
	params: {
		awsRegion: desc:         "Aws Default Region"
		bucketName: desc:        "The name of the S3 bucket to deploy the static website"
		awsCredentialName: desc: "The name of the secret that contains the AWS credentials"
		deployTargetDir: {
			desc:    "The path to the frontend build working directory"
			default: "dist"
		}
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [

		{
			image:      "amazon/aws-cli:2.23.6"
			name:       "deploy"
			workingDir: "$(workspaces.shared.path)/source"
			script: """
				#!/usr/bin/env bash
				echo $DEPLOY_TARGET_DIR
				if aws s3 ls "s3://$BUCKET_NAME" > /dev/null 2>&1; then
					aws s3 cp "$DEPLOY_TARGET_DIR" "s3://$BUCKET_NAME/" --recursive
					results_url="https://$(params.awsRegion).console.aws.amazon.com/s3/buckets/$(params.bucketName)"
					echo "files were uploaded to ${results_url}"
					echo ${results_url} > /tekton/results/uploadedBucketUrl
				else
					echo "SKIP: s3: bucket not found"
					echo "" > /tekton/results/uploadedBucketUrl
				fi
				"""
			volumeMounts: [{
				name:      "aws-secret"
				mountPath: "/secret/aws"
				readOnly:  true
			}]
			env: [{
				name:  "AWS_DEFAULT_REGION"
				value: "$(params.awsRegion)"
			}, {
				name:  "AWS_SHARED_CREDENTIALS_FILE"
				value: "/secret/aws/credentials"
			},
				{
					name:  "DEPLOY_TARGET_DIR"
					value: "$(workspaces.shared.path)/source/$(params.deployTargetDir)"
				},
				{
					name:  "BUCKET_NAME"
					value: "$(params.bucketName)"
				},
			]
			securityContext: runAsUser: 0
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
