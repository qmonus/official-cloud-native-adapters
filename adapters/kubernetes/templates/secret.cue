package templates

import (
	"list"

	"qmonus.net/adapter/official/kubernetes:types"
	"qmonus.net/adapter/official/types:base"
)

#secretType:
	*"Opaque" |
	"kubernetes.io/service-account-token" |
	"kubernetes.io/dockercfg" |
	"kubernetes.io/dockerconfigjson" |
	"kubernetes.io/basic-auth" |
	"kubernetes.io/ssh-auth" |
	"kubernetes.io/ssh-auth" |
	"kubernetes.io/tls" |
	"bootstrap.kubernetes.io/token"

k8sExternalSecret: types.#ExternalSecret & {
	#name:      string
	#namespace: string
	#secrets: [string]: base.#Secret
	#clusterSecretStoreName: string
	#refreshInterval:        string | *"1h"
	#type:                   #secretType

	metadata: {
		name:      #name
		namespace: #namespace
	}

	spec: {
		refreshInterval: #refreshInterval
		secretStoreRef: {
			name: #clusterSecretStoreName
			kind: "ClusterSecretStore"
		}
		_data: [
			for k, v in #secrets {
				secretKey: k
				remoteRef: {
					key:     v.key
					version: v.version
				}
			},
		]
		target: {
			name:           #name
			creationPolicy: "Owner"
			template: {
				type: #type
				if #type == "kubernetes.io/tls" {
					data: {
						// The assumption is that #secret contains only two element.
						"tls.crt": "{{ .\(_data[0].secretKey) | toString }}"
						"tls.key": "{{ .\(_data[1].secretKey) | toString }}"
					}
				}
				if #type == "kubernetes.io/dockerconfigjson" {
					data: {
						// The assumption is that #secret contains only one element.
						".dockerconfigjson": "{{ .\(_data[0].secretKey) | toString }}"
					}
				}
			}
		}
		data: list.Sort(_data, {x: {}, y: {}, less: x.secretKey < y.secretKey})
	}
}

k8sSecret: {
	#name:      string
	#namespace: string
	#secrets: [string]: _
	#type:      #secretType
	apiVersion: "v1"
	kind:       "Secret"
	metadata: {
		name:      #name
		namespace: #namespace
	}
	type: #type
	_unsortKeys: [
		for k, v in #secrets {k},
	]
	_sortedKeys: list.Sort(_unsortKeys, list.Ascending)
	data: {for k in _sortedKeys {
		"\(k)": #secrets["\(k)"]
	}}
}
