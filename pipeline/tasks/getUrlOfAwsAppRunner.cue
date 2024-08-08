package getUrlOfAwsAppRunner

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "get-url-aws-app-runner"

	input: #BuildInput

	results: {
		serviceUrl: {
			description: "app runner service url"
		}
	}

	let _stack = "$(params.appName)-$(params.qvsDeploymentName)-$(params.deployStateName)"

	params: {
		appName: desc:           "Application Name of QmonusVS"
		qvsDeploymentName: desc: "Deployment Name of QmonusVS"
		deployStateName: {
			desc:    "Used as pulumi-stack name suffix"
			default: "app"
		}
		serviceName: desc: "App Runner Service Name"
	}
	steps: [{
		name:       "get-url"
		image:      "python:3.12.4-alpine3.20"
		script:     """
			#!/usr/bin/env python3
			import json
			import sys

			with open('$(workspaces.shared.path)/pulumi/\(_stack)/.pulumi/stacks/local/\(_stack).json') as f:
			    stack = json.load(f)

			# If all resources have been deleted, pulumi stack only has 'pulumi:pulumi:Stack' resource
			if len(stack['checkpoint']['latest']['resources']) == 1 and stack['checkpoint']['latest']['resources'][0]['type'] == 'pulumi:pulumi:Stack':
			    print('There are no resources.')
			    f = open('/tekton/results/serviceUrl', 'w')
			    f.write('')
			    f.close()
			    sys.exit(0)

			for resource in stack['checkpoint']['latest']['resources']:
			    if resource['type'] == 'aws:apprunner/service:Service' and resource['inputs']['serviceName'] == '$(params.serviceName)':
			        f = open('/tekton/results/serviceUrl', 'w')
			        f.write('https://' + resource['outputs']['serviceUrl'])
			        f.close()
			        print('serviceUrl: "' + resource['outputs']['serviceUrl'] + '" was saved successfully.')
			        break
			else:
			    print('Could not find specified "aws:apprunner/service:Service" resource in pulumi stack.')
			    f = open('/tekton/results/serviceUrl', 'w')
			    f.write('')
			    f.close()
			    sys.exit(1)
			"""
		workingDir: "$(workspaces.shared.path)"
	}]
	workspaces: [{
		name: "shared"
	}]
}
