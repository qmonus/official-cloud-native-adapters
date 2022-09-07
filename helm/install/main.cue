package install

import (
	"qmonus.net/adapter/official/kubernetes:types"
)

#ChartParams: {
	qvsResourceId:    string
	helmReleaseName:  string | *qvsResourceId
	helmChartName:    string
	helmChartVersion: string | *null
	k8sNamespace:     string | *null
	helmChartRepoUrl: string
}

DesignPattern: {
	name: "helm:install"

	parameters: {
		charts: [...#ChartParams]
	}

	resources: app: _chartGroup

	_chartGroup: {
		for x in parameters.charts {
			"helm:install-\(x.qvsResourceId)": types.#ChartOpts
			"helm:install-\(x.qvsResourceId)": {
				releaseName: x.helmReleaseName
				chart:       x.helmChartName
				if x.helmChartVersion != null {
					version: x.helmChartVersion
				}
				if x.k8sNamespace != null {
					namespace: x.k8sNamespace
				}
				fetchOpts: {
					repo: x.helmChartRepoUrl
				}
			}
		}
	}
}
