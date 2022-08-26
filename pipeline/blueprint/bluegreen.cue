package bluegreen

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BlueGreenBlueprint: schema.#Blueprint
#BlueGreenBlueprint: {
	#Env: {
		nonProd: "non-prod"
		prod:    "prod"
	}

	deploy:  _
	release: _
	...
}

DesignPattern: {
	name:      "blueprint:bluegreen"
	pipelines: #BlueGreenBlueprint
}
