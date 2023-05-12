package loadbalancer

import (
	"strconv"

	corev1 "k8s.io/api/core/v1"
	"qmonus.net/adapter/official/kubernetes:types"
)

DesignPattern: {
	name: "sample:loadbalancer"

	parameters: {
		appName:      string
		k8sNamespace: string
		port:         string
	}

	resources: app: {
		service: _service
	}

	_service: types.#Service & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.k8sNamespace
		}
		spec: {
			type: corev1.#ServiceTypeLoadBalancer
			ports: [{
				protocol:   corev1.#ProtocolTCP
				port:       strconv.Atoi(parameters.port)
				name:       "http-port"
				targetPort: strconv.Atoi(parameters.port)
			}, ...]
			selector: {
				app: parameters.appName
			}
		}
	}
}
