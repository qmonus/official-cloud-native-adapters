package eso

import (
	"qmonus.net/adapter/official/helm/install"
)

_qvsResourceId:    "external-secrets-operator"
_helmReleaseName:  "external-secrets-operator"
_helmChartName:    "external-secrets"
_helmChartRepoUrl: "https://charts.external-secrets.io"

DesignPattern: {
	name: "secrets:eso"

	parameters: {
		version:      string
		k8sNamespace: string | *"qmonus-system"
	}

	composites: [
		{
			pattern: install.DesignPattern
			params: {
				charts: [
					{
						qvsResourceId:    _qvsResourceId
						helmReleaseName:  _helmReleaseName
						helmChartName:    _helmChartName
						helmChartVersion: parameters.version
						k8sNamespace:     parameters.k8sNamespace
						helmChartRepoUrl: _helmChartRepoUrl
					},
				]
			}
		},
	]

	resources: app: {
		"\(install.DesignPattern.name)-\(_qvsResourceId)": _chartOpts
	}

	_chartOpts: values: {
		serviceAccount:
			create: false
		installCRDs: false
	}
}
