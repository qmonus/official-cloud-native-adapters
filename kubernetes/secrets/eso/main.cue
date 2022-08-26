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
		version:   string
		namespace: string | *"qmonus-system"
	}

	composites: [
		{
			pattern: install.DesignPattern
			params: {
				charts: [
					{
						rid:       _qvsResourceId
						name:      _helmReleaseName
						chart:     _helmChartName
						version:   parameters.version
						namespace: parameters.namespace
						repoUrl:   _helmChartRepoUrl
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
