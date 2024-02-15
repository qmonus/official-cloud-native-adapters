package generateEnvironmentVariablesFile

import (
	"list"
	"strings"
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "generate-environment-variables-file"
	input: #BuildInput

	appconfigParams: [...string]
	params: {
		qvsConfigPath: desc: "Path to QVS Config"
		for i in appconfigParams {
			"\(i)": {
				desc: params[i].desc | *"Parameter used in QVS Config"
			}
		}
	}

	workspaces: [{
		name: "shared"
	}]

	let _envFileDir = "$(workspaces.shared.path)/env"
	let _envFileName = "environment_variables.sh"
	let _envParamName = "environmentVariables"
	let _envSetName = "env_set.txt"
	let _paramsJsonPath = "$(workspaces.shared.path)/params.json"

	steps: [{
		name:       "check-env"
		image:      "linuxserver/yq:3.2.3"
		script:     """
			QVS_JSON=`cat $(params.qvsConfigPath) | yq`
			ENVS=`echo ${QVS_JSON} | jq -c ".designPatterns[]? | .params // empty | .\(_envParamName) // empty"`
			ENV_FILE_DIR="\(_envFileDir)"
			ENV_SET_NAME="\(_envSetName)"

			if [ -z "$ENVS" ]; then
			  echo "no environment variables."
			  exit 0
			fi

			echo "found `echo $ENVS | jq 'to_entries | length'` environment variables."
			mkdir -p $ENV_FILE_DIR
			echo $ENVS | jq  -c 'to_entries | .[]' > ${ENV_FILE_DIR}/${ENV_SET_NAME}
			"""
		workingDir: "$(workspaces.shared.path)/source/"
	}, {
		name:   "make-params-json"
		image:  "python"
		script: strings.Join(list.Concat([
			[
				"#!/usr/bin/env python3",
				"import json",
				"import os",
				"import sys",
				"params = []",
			],
			[
				"if not os.path.isfile('\(_envFileDir)/\(_envSetName)'):",
				"  print('skip making params.json.')",
				"  sys.exit()",
			],
			[ for k in appconfigParams {
				"params.append({'name': '\(k)', 'value': '$(params.\(k))'})"
			}],
			[
				"print(json.dumps({'params': params}, indent=4))",
				"open('$(workspaces.shared.path)/params.json', 'w').write(json.dumps({'params': params}, indent=4))",
			],
		]), "\n")
		workingDir: "$(workspaces.shared.path)/source/"
	}, {
		name:       "generate-env-file"
		image:      "linuxserver/yq:3.2.3"
		script:     """
			ENV_FILE_PATH="\(_envFileDir)/\(_envFileName)"
			ENV_SET_PATH="\(_envFileDir)/\(_envSetName)"

			if [ ! -e $ENV_SET_PATH ]; then
			  echo "skip generating env file"
				exit 0
			fi

			if [ -e $ENV_FILE_PATH ]; then
			  rm $ENV_FILE_PATH
			fi

			PARAMS_JSON_PATH="\(_paramsJsonPath)"

			while read -r ENV; do
			  _KEY=`echo $ENV | jq -r '.key'`
			  _PARAM=`echo $ENV | jq -r  '.value'`
			  case $_PARAM in
			    '$''(params.'*')')
			      _PARAM_NAME=$(echo $_PARAM | cut -c 10-$(expr ${#_PARAM} - 1))
			      _VALUE=$(cat $PARAMS_JSON_PATH | jq -c ".params[] | select(.name == \\"$_PARAM_NAME\\") | .value")
			      echo export ${_KEY}=${_VALUE} >> $ENV_FILE_PATH;;
			    *)
			      echo export ${_KEY}=${_PARAM} >> $ENV_FILE_PATH;;
			  esac
			done < ${ENV_SET_PATH}

			echo "successfully created a env file."
			"""
		workingDir: "$(workspaces.shared.path)/source/"
	}]
}
