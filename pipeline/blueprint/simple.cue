package simple

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#SimpleBlueprint: schema.#Blueprint
#SimpleBlueprint: {
	#Env: {
		nonProd: "non-prod"
		prod:    "prod"
	}

	deploy: _
	...
}

DesignPattern: {
	name:      "blueprint:simple"
	pipelines: #SimpleBlueprint
}
