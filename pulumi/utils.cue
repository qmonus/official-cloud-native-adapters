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

#kebabToPascal: {
	input: string
	let _input_list = strings.Split(input, "-")
	let _transformed = [ for i in _input_list {strings.ToTitle(i)}]
	out: "\(strings.Join(_transformed, ""))"
}
