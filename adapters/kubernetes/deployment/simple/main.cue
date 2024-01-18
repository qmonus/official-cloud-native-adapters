package simple

import (
	"qmonus.net/adapter/official/types:kubernetes"

	"strconv"
)

DesignPattern: {
	name: "official:simple"

	parameters: {
		appName:      string
		k8sNamespace: string
		imageName:    string
		args?: [...string]
		env?: [..._#env]
		port:     string
		replicas: string | *"1"

		_#env: {
			name:  string
			value: string
		}
	}

	let _k8sProvider = "K8sProvider_simple"
	let _deployment = "K8sDeployment_simple"

	parameters: #resourceId: {
		k8sProvider: _k8sProvider
		deployment:  _deployment
	}

	resources: app: {
		"\(_k8sProvider)": kubernetes.#K8sProvider

		"\(_deployment)": kubernetes.#K8sDeployment & {
			options: {
				provider: "${\(_k8sProvider)}"
			}
			properties: {
				metadata: {
					name:      parameters.appName
					namespace: parameters.k8sNamespace
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
	}
}
