package gitCheckout

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	repositoryKind: "gitlab" | *"github"
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "git-checkout"
	input: #BuildInput

	// Sets the git-token prefix string for the specified git-provider
	let _gitToken = {
		if input.repositoryKind == "github" {
			"${GIT_TOKEN}:x-oauth-basic"
		}

		if input.repositoryKind == "gitlab" {
			"oauth2:${GIT_TOKEN}"
		}

	}

	prefixAllParams: true

	params: {
		gitCloneUrl: desc: "URL of the GIT repository with https protocol"
		gitRevision: desc: "Git source revision"
		gitRepositoryDeleteExisting: {
			desc:    "Clean out of the destination directory if it already exists before cloning"
			default: "true"
		}
		gitCheckoutSubDirectory: {
			desc:    "Subdirectory in the source directory to clone Git repository"
			default: ""
		}
		gitTokenSecretName: desc: "Git token sercret name"
	}
	workspaces: [{
		name: "shared"
	}]

	results: {
		gitCommitId: {
			description: "Git commit ID that was checked out by this Task"
		}
		gitCheckoutDirectory: {
			description: "The directory that was cloned repository by this Task"
		}
	}

	steps: [{
		name:  "clean-dir"
		image: "docker:git"
		env: [{
			name:  "GIT_REPO_DELETE_EXISTING"
			value: "$(params.gitRepositoryDeleteExisting)"
		}, {
			name:  "GIT_CHECKOUT_DIR"
			value: "$(workspaces.shared.path)/source/$(params.gitCheckoutSubDirectory)"
		}]
		// The clean process is based on the following.
		// ref: https://github.com/tektoncd/catalog/blob/main/task/git-clone/0.5/git-clone.yaml
		//
		// The reason for putting a blank line at the end is 
		// to leave the last line break after evaluation
		script: """
			if [ "${GIT_REPO_DELETE_EXISTING}" = "true" ]; then
			  if [ -d "${GIT_CHECKOUT_DIR}" ]; then
			    # Delete non-hidden files and directories
			    rm -rf "${GIT_CHECKOUT_DIR:?}"/*
			    # Delete files and directories starting with . but excluding ..
			    rm -rf "${GIT_CHECKOUT_DIR}"/.[!.]*
			    # Delete files and directories starting with .. plus any other character
			    rm -rf "${GIT_CHECKOUT_DIR}"/..?*
			  fi
			fi

			"""
	}, {
		name:   "git-clone"
		image:  "docker:git"
		script: """
			set +x
			GIT_REPOSITORY_URL=`echo $(params.gitCloneUrl) | sed "s/https:\\/\\///g"`
			GIT_TOKEN=`echo ${GIT_TOKEN} | sed "s/^ //" | sed "s/^　//" | sed "s/ $//" | sed "s/　$//"`
			git clone https://\(_gitToken)@${GIT_REPOSITORY_URL} ${GIT_CHECKOUT_DIR}
			set -x
			"""
		env: [{
			name: "GIT_TOKEN"
			valueFrom: secretKeyRef: {
				key:  "token"
				name: "$(params.gitTokenSecretName)"
			}
		}, {
			name:  "GIT_CHECKOUT_DIR"
			value: "$(workspaces.shared.path)/source/$(params.gitCheckoutSubDirectory)"
		}]
	}, {
		name:  "git-checkout"
		image: "docker:git"
		script: """
			cd ${GIT_CHECKOUT_DIR}
			git fetch origin $(params.gitRevision)
			git checkout $(params.gitRevision)
			git rev-parse $(params.gitRevision) | tr -d '\\n' | tee $(results.gitCommitId.path)
			echo ""
			echo -n ${GIT_CHECKOUT_DIR} | tee $(results.gitCheckoutDirectory.path)

			"""
		env: [{
			name:  "GIT_CHECKOUT_DIR"
			value: "$(workspaces.shared.path)/source/$(params.gitCheckoutSubDirectory)"
		}]
	}]
}
