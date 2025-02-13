package templates

import (
	"strconv"

	"qmonus.net/adapter/official/kubernetes:types"
)

#path: {
	pathType:    *"Prefix" | "Exact" | "ImplementationSpecific"
	path:        string
	serviceName: string
	servicePort: string
}

k8sIngressForAzure: types.#Ingress & {
	#name:      string
	#namespace: string
	#annotations: [string]: string
	#host:          string
	#tlsSecretName: string
	#paths: [...#path]

	metadata: {
		name:        #name
		namespace:   #namespace
		annotations: #annotations & {
			"kubernetes.io/ingress.class": "azure/application-gateway"
		}
	}
	spec: {
		if #tlsSecretName != _|_ {
			tls: [{
				hosts: [#host]
				secretName: #tlsSecretName
			}]
		}
		rules: [{
			host: #host
			http: {
				paths: [
					for v in #paths {
						path:     v.path
						pathType: v.pathType
						backend: {
							service: {
								name: v.serviceName
								port: {
									number: strconv.Atoi(v.servicePort)
								}
							}
						}
					},
				]
			}
		}]
	}
}
