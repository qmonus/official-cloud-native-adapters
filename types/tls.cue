package tls

import "qmonus.net/adapter/official/types:base"

#TlsProvider: {
	base.#Resource
	type: "pulumi:providers:tls"
}

#TlsPrivateKey: {
	base.#Resource
	type: "tls:PrivateKey"
}
