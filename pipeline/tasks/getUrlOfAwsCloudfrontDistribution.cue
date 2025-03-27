package getUrlOfAwsCloudfrontDistribution

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "get-url-cloudfront-distribution"

	input: #BuildInput

	results: {
		publicUrl: {
			description: "aws cloudfront distribution url"
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
		name:       "get-url"
		image:      "python:3.12.4-alpine3.20"
		script:     """
            #!/usr/bin/env python3
            import json
            import sys
            import os

            with open('$(workspaces.shared.path)/pulumi/\(_stack)/.pulumi/stacks/local/\(_stack).json') as f:
                stack = json.load(f)

            # If all resources have been deleted, pulumi stack only has 'pulumi:pulumi:Stack' resource
            if len(stack['checkpoint']['latest']['resources']) == 1 and stack['checkpoint']['latest']['resources'][0]['type'] == 'pulumi:pulumi:Stack':
                print('There are no resources.')
                f = open('/tekton/results/publicUrl', 'w')
                f.write('')
                f.close()
                sys.exit(0)
            for resource in stack['checkpoint']['latest']['resources']:
                if resource['type'] == 'aws:cloudfront/distribution:Distribution':
                    f = open('/tekton/results/publicUrl', 'w')
                    f.write('https://' + resource['outputs']['domainName'])
                    f.close()
                    print("publicUrl: https://" + resource['outputs']['domainName'] + " was saved successfully.")
                    break
            else:
                print("Could not find specified 'aws:cloudfront/distribution:Distribution' resource in pulumi stack.")
                f = open('/tekton/results/publicUrl', 'w')
                f.write('')
                f.close()
                sys.exit(1)
            """
		workingDir: "$(workspaces.shared.path)"
		env: []
	}]
	workspaces: [{
		name: "shared"
	}]
}
