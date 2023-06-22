package mysql

import (
	"qmonus.net/adapter/official/pulumi/base/mysql"
)

DesignPattern: {
	name: "mysql:provider"

	parameters: {
		providerName: string | *"\(mysql.default.provider)"
		endpoint:     string | *"localhost"
		username:     string | *"adminuser"
	}

	resources: app: {
		"\(parameters.providerName)": mysql.#Resource & {
			// See the link below for the API detail.
			// https://www.pulumi.com/registry/packages/mysql/api-docs/provider/
			type: "pulumi:providers:mysql"
			properties: {
				endpoint: parameters.endpoint
				username: parameters.username
				// use hard code password
				password: "P@ssw0rd"
			}
		}
	}
}
