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

#trim: {
	str:   string
	limit: int

	// trim "str" depending on whether length of "str" exceeds "limit"
	if strings.MaxRunes(str, limit) {
		out: str
	}
	if !strings.MaxRunes(str, limit) {
		out: strings.SliceRunes(str, 0, limit)
	}
}
