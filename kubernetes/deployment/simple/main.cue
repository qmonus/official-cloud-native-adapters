package simple

import (
	"strconv"

	"qmonus.net/adapter/official/kubernetes:types"
)

DesignPattern: {
	name: "official:simple"

	parameters: {
		appName:   string
		namespace: string
		imageName: string
		args?: [...string]
		env?: [..._#env]
		port:     string
		replicas: string | *"1"

		_#env: {
			name:  string
			value: string
		}
	}

	resources: app: {
		deployment: _deployment
	}

	_deployment: types.#Deployment & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.namespace
		}
		spec: {
			minReadySeconds: int | *60
			replicas:        strconv.Atoi(parameters.replicas)
			selector: matchLabels: {
				app: parameters.appName
			}
			template: {
				metadata: labels: {
					app: parameters.appName
				}
				spec: {
					terminationGracePeriodSeconds: int | *60
					containers: [
						{
							name:  parameters.appName
							image: parameters.imageName
							ports: [{
								containerPort: strconv.Atoi(parameters.port)
							}, ...]
							if parameters.args != _|_ {
								args: parameters.args
							}
							if parameters.env != _|_ {
								env: parameters.env
							}
						},
						// keep the list open to allow adding a sidecar container in different Design Patterns
						...,
					]
				}
			}
		}
	}
}
