package utils

import (
	"strings"
)

#kebabToPascal: {
	input: string
	let _input_list = strings.Split(input, "-")
	let _transformed = [ for i in _input_list {strings.ToTitle(i)}]
	out: "\(strings.Join(_transformed, ""))"
}
