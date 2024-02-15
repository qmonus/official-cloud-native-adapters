package getUrlOfGcpFirebaseHosting

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "get-url-gcp-firebase-hosting"

	input: #BuildInput

	results: {
		defaultDomain: {
			description: "Firebase Hosting default domain url"
		}
		customDomain: {
			description: "Firebase Hosting custom domain url"
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
	}
	steps: [{
		name:       "get-domains"
		image:      "python:3.12-alpine3.19"
		script:     """
			#!/usr/bin/env python3
			import json
			import sys

			with open('$(workspaces.shared.path)/pulumi/\(_stack)/.pulumi/stacks/local/\(_stack).json') as f:
			    stack = json.load(f)

			for resource in stack['checkpoint']['latest']['resources']:
			    if resource['type'] == 'gcp:firebase/hostingSite:HostingSite':
			        f = open('siteId', 'w')
			        f.write(resource['outputs']['siteId'])
			        f.close()
			        f = open('/tekton/results/defaultDomain', 'w')
			        f.write('https://' + resource['outputs']['siteId'] + '.web.app')
			        f.close()
			        print('siteId: "' + resource['outputs']['siteId'] + '" was saved successfully.')
			        break
			else:
			    print('Could not find "gcp.firebase.HostingSite" resource in pulumi stack.')
			    f = open('/tekton/results/defaultDomain', 'w')
			    f.write('')
			    f.close()

			for resource in stack['checkpoint']['latest']['resources']:
			    if resource['type'] == 'gcp:firebase/hostingCustomDomain:HostingCustomDomain':
			        f = open('/tekton/results/customDomain', 'w')
			        f.write('https://' + resource['outputs']['customDomain'])
			        f.close()
			        print('customDomain: "' + resource['outputs']['customDomain'] + '" was saved successfully.')
			        break
			else:
			    print('Could not find "gcp:firebase/hostingCustomDomain:HostingCustomDomain" resource in pulumi stack.')
			    f = open('/tekton/results/customDomain', 'w')
			    f.write('')
			    f.close()
			"""
		workingDir: "$(workspaces.shared.path)"
	}]
	workspaces: [{
		name: "shared"
	}]
}
