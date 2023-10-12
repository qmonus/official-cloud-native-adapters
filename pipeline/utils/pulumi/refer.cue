package refer

import (
	"list"
	"strings"
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#PipelineParams: {
	jqQueries: [...#JqQueries]
	#JqQueries: {
		name:    string
		filter?: string
		query?: {
			selector: string
			path:     string
		}
	}
}

DesignPattern: {
	name:               "pulumi:refer"
	pipelineParameters: #PipelineParams
	pipelines: {
		refer: {
			tasks: "refer": #TaskBuilder & {
				input: JqQueries: pipelineParameters.jqQueries
			}
			results: tasks["refer"].results
		}
	}
}
#BuildInput: {
	#PipelineParams
	...
}
#TaskBuilder: schema.#TaskBuilder
#TaskBuilder: {
	name:  "refer-to-pulumi-stack"
	input: #BuildInput
	params: {
		referAppName: desc:        "Application name used to refer to the Pulumi stack"
		referDeploymentName: desc: "Deployment name used to refer to the Pulumi stack"
		referDeploymentStateName: {
			desc:    "Deployment state name used to refer to the Pulumi stack"
			default: "main"
		}
	}
	let _workingDir = "$(workspaces.shared.path)/pulumi/refer"
	let _stackName = "$(params.referAppName)-$(params.referDeploymentName)-$(params.referDeploymentStateName)"
	let _stackPath = "\(_workingDir)/.pulumi/stacks/local/\(_stackName).json"
	steps: [{
		name:   "download-state"
		image:  "google/cloud-sdk:365.0.1-slim@sha256:2575543b18e06671eac29aae28741128acfd0e4376257f3f1246d97d00059dcb"
		script: """
			#!/usr/bin/env bash
			set -o nounset
			set -o xtrace
			set -o pipefail

			mkdir -p '\(_workingDir)'
			cd '\(_workingDir)'
			if [[ -d .pulumi ]]; then
			  exit 0
			fi
			SIGNED_URL=`curl -X POST -fs ${VS_API_ENDPOINT}'/apis/v1/projects/$(context.taskRun.namespace)/applications/$(params.referAppName)/deployments/$(params.referDeploymentName)/deploy-state/$(params.referDeploymentStateName)/action/signed-url-to-get?taskrun_name=$(context.taskRun.name)&taskrun_uid=$(context.taskRun.uid)' | xargs`
			mkdir -p /tekton/home/pulumi/old
			STATUS=`curl -fs ${SIGNED_URL} -o /tekton/home/pulumi/old/state.tgz -w '%{http_code}\\n'`
			if [ ! -z $STATUS ] && [ $STATUS -eq 404 ]; then
			  echo "No state file is provided. Create a new state."
			  exit 0
			elif [ -z $STATUS ] || [ $STATUS -ne 200 ]; then
			  echo "Error: failed to download state file."
			  exit 1
			fi
			if [ -f /tekton/home/pulumi/old/state.tgz ]; then
			  tar xzvf /tekton/home/pulumi/old/state.tgz
			else
			  echo "Error: status_code is 200 but no state file is provided."
			  exit 1
			fi

			"""
		env: [{
			name: "VS_API_ENDPOINT"
			valueFrom: fieldRef: fieldPath: "metadata.annotations['\(base.config.vsApiEndpointKey)']"
		}]
	}, {
		name:   "refer-to-pulumi-stack"
		image:  "linuxserver/yq"
		script: strings.Join(list.Concat([
			[
				"#!/bin/bash",
				"STACKPATH=\(_stackPath)",
			],
			[ for jqq in input.JqQueries {
				if jqq.filter != _|_ {
					"""
					VALUE=`jq -r '\(jqq.filter)' $STACKPATH | head -c -1`
					if [ $VALUE == null ] || [ -z $VALUE ]; then
						echo "Error: Unable to get value using jq query"
						echo "fileter: \(jqq.filter)"
						exit 1
					else
						NAME="\(jqq.name)"
						echo "Param $NAME got: $VALUE"
						echo -n $VALUE > "/tekton/results/$NAME"
					fi
					"""
				}
				if jqq.filter == _|_ {
					"""
					VALUE=`jq -r '.checkpoint.latest.resources[] | select(\(jqq.query.selector)) | \(jqq.query.path)' $STACKPATH | head -c -1`
					if [ $VALUE == null ] || [ -z $VALUE ]; then
						echo "Error: Unable to get value using jq query"
						echo "selector: \(jqq.query.selector)"
						echo "path: \(jqq.query.path)"
						exit 1
					else
						NAME="\(jqq.name)"
						echo "Param $NAME got: $VALUE"
						echo -n $VALUE > "/tekton/results/$NAME"
					fi
					"""
				}
			}],
		]), "\n")
	}]

	workspaces: [{
		name: "shared"
	}]

	results: {
		for jqq in input.JqQueries {
			"\(jqq.name)": description: "Parameters taken from the Pulumi stack"
		}
	}

}
