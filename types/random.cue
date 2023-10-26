package random

import "qmonus.net/adapter/official/types:base"

#RandomProvider: {
	base.#Resource
	type: "pulumi:providers:random"
}

#RandomPassword: {
	base.#Resource
	type: "random:RandomPassword"
}

#RandomString: {
	base.#Resource
	type: "random:RandomString"
}
