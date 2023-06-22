package compileAdapterIntoPulumiYaml

import (
	"list"
	"strings"
	"qmonus.net/adapter/official/pipeline/schema"
	"qmonus.net/adapter/official/pipeline/base"
)

#BuildInput: {
	phase:           "app" | *""
	importStackName: string | *""

	// TaskBuilder Developper Defined Parameter
	useDebug:         bool | *false
	resourcePriority: "high" | *"medium"
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name: "compile-adapter-into-pulumi-yaml"

	input:  #BuildInput
	prefix: input.phase
	// appconfigParams value exists in #TaskBuilder
	appconfigParams: [...string]

	// This Task requires application secrets
	useAppSecrets: true

	let _input = input

	params: {
		pathToSource: {
			desc:    "Relative path from source directory"
			default: ""
		}
		qvsConfigPath: desc:      "Path to QVS Config"
		gitTokenSecretName: desc: "Git token sercret name"
		for i in appconfigParams {
			"\(i)": {
				desc: params[i].desc | *"Parameter used in QVS Config"
			}
		}
	}

	workspaces: [{
		name: "shared"
	}]

	volumes: [{
		name: "tmpdir"
		emptyDir: {}
	}]

	steps: list.Concat([[{
		name:   "make-params-json"
		image:  "python"
		script: strings.Join(list.Concat([
			[
				"#!/usr/bin/env python3",
				"import json",
				"import os",
				"params = []",
			],
			[
				"params.append({'name': 'pathToSharedSource', 'value': '$(workspaces.shared.path)/source/'})", // Reserved parameter passing source code path to manfiest.
			],
			[ for k in appconfigParams {
				"params.append({'name': '\(k)', 'value': '$(params.\(k))'})"
			}],
			[
				"vs_secrets = os.environ.get('VS_SECRETS')",
				"secrets = json.loads(vs_secrets) if vs_secrets else []",
			],
			[
				"print(json.dumps({'params': params, 'secrets': secrets}, indent=4))",
				"open('$(workspaces.shared.path)/params.json', 'w').write(json.dumps({'params': params, 'secrets': secrets}, indent=4))",
			],
		]), "\n")
		env: [{
			name: "VS_SECRETS"
			valueFrom: fieldRef: fieldPath: "metadata.annotations['\(base.config.qmonusVsSecretKey)']"
		}]
		workingDir: "$(workspaces.shared.path)/source/$(params.pathToSource)"
	}], _compileStep, _debugStep])

	_compileStep: [{
		name:  "compile-app"
		image: "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/qvsctl:\(base.config.qmonusQvsctlRevision)"
		_args: [
			"manifest",
			"compile",
			"-o",
			"$(workspaces.shared.path)/manifests/pulumi/Pulumi.yaml",
			"-c",
			"$(params.qvsConfigPath)",
			"-p",
			"$(workspaces.shared.path)/params.json",
			"--output-format",
			"pulumi",

		]
		if _input.importStackName == "" {
			args: _args
		}
		if _input.importStackName != "" {
			args: _args + [
				"--stack",
				"\(_input.importStackName)",
			]
		}
		env: [{
			name: "GIT_TOKEN"
			valueFrom: secretKeyRef: {
				name: "$(params.gitTokenSecretName)"
				key:  "token"
			}
		}, {
			name:  "TMPDIR"
			value: "/tmpdir"
		}]

		volumeMounts: [{
			mountPath: "/tmpdir"
			name:      "tmpdir"
		}]

		workingDir: "$(workspaces.shared.path)/source/$(params.pathToSource)"
		resources: {
			if _input.resourcePriority == "medium" {
				requests: {
					cpu:    "1"
					memory: "512Mi"
				}
				limits: {
					cpu:    "1"
					memory: "512Mi"
				}
			}
			if _input.resourcePriority == "high" {
				requests: {
					cpu:    "1"
					memory: "1Gi"
				}
				limits: {
					cpu:    "1"
					memory: "1Gi"
				}
			}
		}
	},
	]

	_debugStep: [
		if _input.useDebug {
			name:  "check-manifest"
			image: "bash:latest"
			script: """
				#!/usr/bin/env bash
				if [ -e $(workspaces.shared.path)/manifests/pulumi/Pulumi.yaml ]; then
					echo '[app]\\n'
					cat $(workspaces.shared.path)/manifests/pulumi/Pulumi.yaml
				fi
				"""
		},
	]
}
