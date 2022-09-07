package utils

import (
	"strings"
)

#addPrefix: {
	_prefix="prefix": string
	_key="key":       string

	if _prefix == "" {
		out: _key
	}
	if _prefix != "" {
		out: "\(strings.ToLower(_prefix))\(strings.ToTitle(_key))"
	}
}

#concatKebab: {
	input: [...string]
	let _filtered = [ for i in input if i != "" {
		i
	}]
	out: strings.Join(_filtered, "-")
}
