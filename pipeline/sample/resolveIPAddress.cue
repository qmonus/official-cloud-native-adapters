package resolveIPAddress

import (
	"qmonus.net/adapter/official/pipeline/tasks:resolveIPAddress"
)

DesignPattern: {
	name: "sample:resolveIPAddress"

	pipelines: {
		"resolve-ip-address-after-deploy": {
			tasks: {
				"resolve-ip-address": resolveIPAddress.#Builder
			}
			results: {
				"ipAddress": tasks["resolve-ip-address"].results.ipAddress
			}
		}
	}
}
