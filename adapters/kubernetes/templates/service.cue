package templates

import (
	"strconv"

	"qmonus.net/adapter/official/kubernetes:types"
)

#port: {
	name?:      string
	protocol:   *"TCP" | "UDP"
	port:       string
	targetPort: string
	nodePort?:  string
}

k8sService: types.#Service & {
	#name:      string
	#namespace: string
	#annotations: [string]: string
	#ports: [...#port]
	#serviceType:  *"ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
	#externalName: string

	metadata: {
		name:      #name
		namespace: #namespace
		// add len condition to avoid generating empty annotations field
		if #annotations != _|_ && len(#annotations) > 0 {
			annotations: #annotations
		}
	}
	spec: {
		type: #serviceType
		if #serviceType != "ExternalName" {
			ports: [
				for v in #ports {
					if v.name != _|_ {
						name: v.name
					}
					protocol:   v.protocol
					port:       strconv.Atoi(v.port)
					targetPort: strconv.Atoi(v.targetPort)
					if v.nodePort != _|_ {
						nodePort?: strconv.Atoi(v.nodePort)
					}
				},
			]
			selector: app: #name
		}
		if #serviceType == "ExternalName" {
			externalName: #externalName
		}
	}
}
