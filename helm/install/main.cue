package install

import (
	"qmonus.net/adapter/official/kubernetes:types"
)

#ChartParams: {
	rid:       string
	name:      string | *rid
	chart:     string
	version:   string | *null
	namespace: string | *null
	repoUrl:   string
}

DesignPattern: {
	name: "helm:install"

	parameters: {
		charts: [...#ChartParams]
	}

	resources: app: _chartGroup

	_chartGroup: {
		for x in parameters.charts {
			"helm:install-\(x.rid)": types.#ChartOpts
			"helm:install-\(x.rid)": {
				releaseName: x.name
				chart:       x.chart
				if x.version != null {
					version: x.version
				}
				if x.namespace != null {
					namespace: x.namespace
				}
				fetchOpts: {
					repo: x.repoUrl
				}
			}
		}
	}
}
