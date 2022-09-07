package publicapi

import (
	"strconv"
	"encoding/json"

	corev1 "k8s.io/api/core/v1"
	"qmonus.net/adapter/official/kubernetes:types"
)

DesignPattern: {
	name: "official:publicapi"

	parameters: {
		appName:                string
		k8sNamespace:           string
		port:                   string
		domainName:             string
		gcpExternalAddressName: string
		gcpSecurityPolicyName:  string
		gcpSslPolicyName:       string | *""
	}

	resources: app: {
		backendconfig: _backendconfig
		service:       _service
		if len(parameters.gcpSslPolicyName) > 0 {
			frontendconfig: _frontendconfig
		}
		ingress:            _ingress
		managedcertificate: _managedcertificate
	}

	_backendconfig: types.#BackendConfig & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.k8sNamespace
		}
		spec: {
			connectionDraining: drainingTimeoutSec: int | *300
			securityPolicy: name:                   parameters.gcpSecurityPolicyName
			timeoutSec: int | *300
			healthCheck: {
				checkIntervalSec: int | *15
				port:             strconv.Atoi(parameters.port)
				requestPath:      "/"
				type:             "HTTP"
			}
		}
	}

	_service: types.#Service & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.k8sNamespace
			annotations: {
				"beta.cloud.google.com/backend-config": json.Marshal(_aBackendConfig)
				"cloud.google.com/neg":                 json.Marshal(_aIngress)
			}
		}
		spec: {
			type: corev1.#ServiceTypeNodePort
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
		_aBackendConfig: ports: {"\(parameters.port)": _backendconfig.metadata.name}
		_aIngress: {ingress: true}
	}

	_frontendconfig: types.#FrontendConfig & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.k8sNamespace
		}
		spec: {
			sslPolicy: parameters.gcpSslPolicyName
		}
	}

	_ingress: types.#Ingress & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.k8sNamespace
			annotations: {
				"kubernetes.io/ingress.allow-http":            "false"
				"kubernetes.io/ingress.class":                 "gce"
				"kubernetes.io/ingress.global-static-ip-name": parameters.gcpExternalAddressName
				"networking.gke.io/managed-certificates":      parameters.appName
				if len(parameters.gcpSslPolicyName) > 0 {
					"networking.gke.io/v1beta1.FrontendConfig": _frontendconfig.metadata.name
				}
			}
		}
		spec: defaultBackend: service: {
			name: parameters.appName
			port: number: strconv.Atoi(parameters.port)
		}
	}

	_managedcertificate: types.#ManagedCertificate & {
		metadata: {
			name:      parameters.appName
			namespace: parameters.k8sNamespace
		}
		spec: domains: [parameters.domainName]
	}
}
