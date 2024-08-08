package aws

import "qmonus.net/adapter/official/types:base"

#AwsProvider: {
	base.#Resource
	type: "pulumi:providers:aws"
}

#QvsManagedLabel: {
	"managed-by": "Qmonus Value Stream"
	{[string]: string}
}

#AwsAppRunnerService: {
	base.#Resource
	type: "aws:apprunner:Service"
	properties: tags: #QvsManagedLabel
}
