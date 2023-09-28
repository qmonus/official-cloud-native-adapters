package mysql

import "qmonus.net/adapter/official/types:base"

#MysqlProvider: {
	base.#Resource
	type: "pulumi:providers:mysql"
}

#MysqlDatabase: {
	base.#Resource
	type: "mysql:Database"
}

#MysqlUser: {
	base.#Resource
	type: "mysql:User"
}

#MysqlGrant: {
	base.#Resource
	type: "mysql:Grant"
}
