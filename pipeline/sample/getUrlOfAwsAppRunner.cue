package getUrlOfAwsAppRunner

import (
	"qmonus.net/adapter/official/pipeline/tasks:getUrlOfAwsAppRunner"
)

DesignPattern: {
	name: "sample:getUrlOfAwsAppRunner"

	pipelines: {
		"get-url": {
			tasks: {
				"get-url": getUrlOfAwsAppRunner.#Builder
			}
			results: {
				"serviceUrl": tasks["get-url"].results.serviceUrl
			}
		}
	}
}
