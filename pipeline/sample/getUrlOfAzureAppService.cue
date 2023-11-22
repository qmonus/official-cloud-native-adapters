package getUrlOfAzureAppService

import (
	"qmonus.net/adapter/official/pipeline/tasks:getUrlOfAzureAppService"
)

DesignPattern: {
	name: "sample:getUrlOfAzureAppService"

	pipelines: {
		"get-url-after-deploy": {
			tasks: {
				"get-url": getUrlOfAzureAppService.#Builder
			}
			results: {
				"defaultDomain": tasks["get-url"].results.defaultDomain
				"customDomain":  tasks["get-url"].results.customDomain
			}
		}
	}
}
