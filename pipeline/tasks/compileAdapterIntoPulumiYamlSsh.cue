package compileAdapterIntoPulumiYamlSsh

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
	name: "compile-adapter-into-pulumi-yaml-ssh"

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
		qvsConfigPath: desc: "Path to QVS Config"
		for i in appconfigParams {
			"\(i)": {
				desc: params[i].desc | *"Parameter used in QVS Config"
			}
		}
		gitSshKeySecretName: desc: "Git ssh key sercret name"
	}

	results: {
		module: {
			description: "Adapter module"
		}
		adapterRevision: {
			description: "Adapter version"
		}
		adapters: {
			description: "List of Adapters used in Assemblyline"
		}
	}

	workspaces: [{
		name: "shared"
	}]

	volumes: [{
		name: "tmpdir"
		emptyDir: {}
	}, {
		name: "ssh-key"
		secret: {
			secretName: "$(params.gitSshKeySecretName)"
			// permission should be 0400
			// use decimal valule, because the type must be int32
			defaultMode: 256
			items: [{
				key:  "ssh_key"
				path: "id_git"
			}]
		}
	}]

	steps: list.Concat([_displayAdapterInfoStep, _makeParamsJsonStep, _compileStep, _debugStep])

	_displayAdapterInfoStep: [{
		name:  "display-adapter-info"
		image: "linuxserver/yq:3.2.3"
		script: """
			#!/usr/bin/env bash

			# Set Default Pipeline Results
			echo -n "" > /tekton/results/module
			echo -n "" > /tekton/results/adapterRevision
			echo -n "" > /tekton/results/adapters

			# Extract module name
			module=$(yq -r '.modules[0].name' $(params.qvsConfigPath))
			echo "module: $module"
			echo -n $module > /tekton/results/module

			# Extract adapter_revision
			module_revision=$(yq -r '.modules[0].revision' $(params.qvsConfigPath))
			module_local_path=$(yq -r '.modules[0].local.path' $(params.qvsConfigPath))
			module_remote_revision=$(yq -r '.modules[0].remote.revision' $(params.qvsConfigPath))			
						
			if [ "$module_revision" == "null" ]; then
				case "$module_local_path" in
					null)
						# Extract adapter_revision when using remote/repo style module
						adapter_revision=$module_remote_revision
						;;
					*)
						# Extract adapter_revision when using local module
						qvsctl_mod_path="$(dirname $(params.qvsConfigPath))/${module_local_path}/qvsctl.mod"
						if [ -r "$qvsctl_mod_path" ]; then
							IFS='@' read -ra separated_list < "$qvsctl_mod_path"
							adapter_revision=${separated_list[1]}
						fi
						;;
				esac
			else
				# Extract adapter_revision when using remote module
				adapter_revision=$module_revision
			fi
			echo "adapter_revision: $adapter_revision"
			echo -n $adapter_revision > /tekton/results/adapterRevision

			# Extract design patterns as a comma-separated line
			adapters=$(yq -r '.designPatterns[].pattern' $(params.qvsConfigPath) | tr '\n' ',' | sed 's/,$//')
			echo "adapters: $adapters"
			echo -n $adapters > /tekton/results/adapters
			"""
		onError:    "continue"
		workingDir: "$(workspaces.shared.path)/source"
	}]

	_makeParamsJsonStep: [
		{
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
					"params.append({'name': '\(k)', 'value': '''$(params.\(k))'''})"
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
		},
	]

	_compileStep: [{
		name:  "compile-app"
		image: "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/qvsctl:\(base.config.qmonusQvsctlRevision)"
		args:  list.FlattenN([
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
			if _input.importStackName != "" {
				[
					"--stack",
					"\(_input.importStackName)",
				]
			},
		], -1)
		env: [{
			name:  "TMPDIR"
			value: "/tmpdir"
		}, {
			name:  "GIT_SSH_KEY_PATH"
			value: "/root/.ssh/id_git"
		}, {
			name:  "QVSCTL_SKIP_UPDATE_CHECK"
			value: "true"
		}]

		volumeMounts: [{
			mountPath: "/tmpdir"
			name:      "tmpdir"
		}, {
			name:      "ssh-key"
			mountPath: "/root/.ssh"
			readOnly:  true
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
