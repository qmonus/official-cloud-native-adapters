package initGitCredentials

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	repositoryKind: "gitlab" | "bitbucket" | *"github"
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "init-git-credentials"
	input: #BuildInput

	// Sets the git-token prefix string for the specified git-provider
	let _gitToken = {
		if input.repositoryKind == "github" {
			"$(GIT_TOKEN)"
		}

		if input.repositoryKind == "gitlab" {
			"oauth2:$(GIT_TOKEN)"
		}

		if input.repositoryKind == "" {
			"$(GIT_TOKEN)"
		}

	}

	prefixAllParams: true

	params: {
		gitTokenSecretName: desc: "Git token sercret name"
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		name:  "init-git-credentials"
		image: "docker:git"
		env: [{
			name: "GIT_TOKEN"
			valueFrom: secretKeyRef: {
				key:  "token"
				name: "$(params.gitTokenSecretName)"
			}
		}]
		args: [
			"config",
			"--file",
			"$(workspaces.shared.path)/.gitconfig",
			"url.https://\(_gitToken)@.insteadOf",
			"https://",
		]
		command: [
			"/usr/bin/git",
		]
	}]
}
