package gitCheckoutSsh

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "git-checkout-ssh"
	input: #BuildInput

	prefixAllParams: true

	params: {
		gitCloneUrl: desc: "URL of the GIT repository without protocol"
		gitRevision: desc: "Git source revision"
		gitRepositoryDeleteExisting: {
			desc:    "Clean out of the destination directory if it already exists before cloning"
			default: "true"
		}
		gitCheckoutSubDirectory: {
			desc:    "Subdirectory in the source directory to clone Git repository"
			default: ""
		}
		gitSshKeySecretName: desc: "Git ssh key sercret name"
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
		name:  "git-clone"
		image: "docker:git"
		env: [{
			name:  "GIT_SSH_COMMAND"
			value: "ssh -i /root/.ssh/id_git -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error"
		}, {
			name:  "GIT_CHECKOUT_DIR"
			value: "$(workspaces.shared.path)/source/$(params.gitCheckoutSubDirectory)"
		}]
		args: [
			"clone",
			"$(params.gitCloneUrl)",
			"$(GIT_CHECKOUT_DIR)",
		]
		command: [
			"/usr/bin/git",
		]
		volumeMounts: [{
			name:      "ssh-key"
			mountPath: "/root/.ssh"
			readOnly:  true
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
			name:  "GIT_SSH_COMMAND"
			value: "ssh -i /root/.ssh/id_git -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error"
		}, {
			name:  "GIT_CHECKOUT_DIR"
			value: "$(workspaces.shared.path)/source/$(params.gitCheckoutSubDirectory)"
		}]
		volumeMounts: [{
			name:      "ssh-key"
			mountPath: "/root/.ssh"
			readOnly:  true
		}]
	}]
	volumes: [{
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
}
