package simpleDeployByPulumiYaml

import (
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckout"
	"qmonus.net/adapter/official/pipeline/tasks:gitCheckoutSsh"
	"qmonus.net/adapter/official/pipeline/tasks:compileAdapterIntoPulumiYaml"
	"qmonus.net/adapter/official/pipeline/tasks:compileAdapterIntoPulumiYamlSsh"
	"qmonus.net/adapter/official/pipeline/tasks:deployByPulumiYaml"
)

DesignPattern: {
	name: "deploy:simpleDeployByPulumiYaml"

	pipelineParameters: {
		repositoryKind:       string | *""
		useDebug:             bool | *false
		deployPhase:          "app" | *""
		resourcePriority:     "high" | *"medium"
		useSshKey:            bool | *false
		pulumiCredentialName: string | *"qmonus-pulumi-secret"
		useCred: {
			kubernetes: bool | *false
			gcp:        bool | *false
			aws:        bool | *false
			azure:      bool | *false
		}
		importStackName:   string | *""
		useBastionSshCred: bool | *false
	}
	let _repositoryKind = pipelineParameters.repositoryKind
	let _useDebug = pipelineParameters.useDebug
	let _deployPhase = pipelineParameters.deployPhase
	let _resourcePriority = pipelineParameters.resourcePriority
	let _pulumiCredentialName = pipelineParameters.pulumiCredentialName
	let _useCred = pipelineParameters.useCred
	let _useSshKey = pipelineParameters.useSshKey
	let _importStackName = pipelineParameters.importStackName
	let _useBastionSshCred = pipelineParameters.useBastionSshCred

	pipelines: {
		deploy: {
			tasks: {
				"checkout": {
					if _repositoryKind == "bitbucket" || _repositoryKind == "backlog" {
						gitCheckoutSsh.#Builder & {
							input: {
								repositoryKind: _repositoryKind
							}
						}
					}

					if _repositoryKind != "bitbucket" && _repositoryKind != "backlog" {
						if _useSshKey {
							gitCheckoutSsh.#Builder & {
								input: {
									repositoryKind: _repositoryKind
								}
							}
						}
						if !_useSshKey {
							gitCheckout.#Builder & {
								input: {
									repositoryKind: _repositoryKind
								}
							}
						}
					}
				}
				"compile": {
					if _repositoryKind == "bitbucket" || _repositoryKind == "backlog" {
						compileAdapterIntoPulumiYamlSsh.#Builder & {
							input: {
								phase:            _deployPhase
								useDebug:         _useDebug
								resourcePriority: _resourcePriority
								importStackName:  _importStackName
							}
							runAfter: ["checkout"]
						}
					}

					if _repositoryKind != "bitbucket" && _repositoryKind != "backlog" {
						if _useSshKey {
							compileAdapterIntoPulumiYamlSsh.#Builder & {
								input: {
									phase:            _deployPhase
									useDebug:         _useDebug
									resourcePriority: _resourcePriority
									importStackName:  _importStackName
								}
								runAfter: ["checkout"]
							}
						}
						if !_useSshKey {
							compileAdapterIntoPulumiYaml.#Builder & {
								input: {
									phase:            _deployPhase
									useDebug:         _useDebug
									resourcePriority: _resourcePriority
									importStackName:  _importStackName
								}
								runAfter: ["checkout"]
							}
						}
					}
				}
				"deploy": deployByPulumiYaml.#Builder & {
					input: {
						phase:                _deployPhase
						pulumiCredentialName: _pulumiCredentialName
						useCred:              _useCred
						useBastionSshCred:    _useBastionSshCred
					}
					runAfter: ["compile"]
				}
			}
			results: {
				module:          tasks["compile"].results.module
				adapterRevision: tasks["compile"].results.adapterRevision
				adapters:        tasks["compile"].results.adapters
			}
		}
	}
}
