package container

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#ContainerBlueprint: schema.#Blueprint
#ContainerBlueprint: {
	#Env: {
		integration: "integration"
		system:      "system"
		production:  "production"
	}

	// explicitly limit
	// build: {
	//  results: image: description: string
	// }
	build:  _
	deploy: _
}
