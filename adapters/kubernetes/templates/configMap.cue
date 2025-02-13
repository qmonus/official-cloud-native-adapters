package templates

import (
	"list"
)

k8sConfigMap: {
	#name:      string
	#namespace: string
	#data: [string]: _

	apiVersion: "v1"
	kind:       "ConfigMap"
	metadata: {
		name:      #name
		namespace: #namespace
	}
	_unsortKeys: [
		for k, v in #data {k},
	]
	_sortedKeys: list.Sort(_unsortKeys, list.Ascending)
	data: {for k in _sortedKeys {
		"\(k)": #data["\(k)"]
	}}
}
