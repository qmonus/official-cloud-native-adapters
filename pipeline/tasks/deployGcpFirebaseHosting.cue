package deployGcpFirebaseHosting

import (
	"qmonus.net/adapter/official/pipeline/base"
	"qmonus.net/adapter/official/pipeline/schema"
)

#BuildInput: {
	...
}

#Builder: schema.#TaskBuilder
#Builder: {
	name:  "deploy-gcp-firebase-hosting"
	input: #BuildInput

	params: {
		appName: desc: "Application Name of QmonusVS"
		buildTargetDir: {
			desc:    "The path to the frontend build working directory"
			default: "."
		}
		deployTargetDir: {
			desc:    "The path to the frontend deploy working directory"
			default: "dist"
		}
		gcpProjectId: desc:                "GCP Project ID"
		gcpServiceAccountSecretName: desc: "The secret name of GCP SA credential"
	}
	workspaces: [{
		name: "shared"
	}]

	steps: [{
		image:      "bash:5.2-alpine3.19"
		name:       "make-configration-files"
		workingDir: "$(workspaces.shared.path)/source/$(params.buildTargetDir)"
		script: """
			#!/usr/bin/env bash
			if [ -e $(workspaces.shared.path)/siteId ]; then
			  FIREBASE_HOSTING_SITE_ID=$(cat $(workspaces.shared.path)/siteId)
			  echo '{"projects": {"default": "'$GCP_PROJECT_ID'"}, "targets": {"'$GCP_PROJECT_ID'": {"hosting": {"'$FIREBASE_HOSTING_SITE_ID'": ["'$FIREBASE_HOSTING_SITE_ID'"]}}},"etags": {}}' > .firebaserc
			  echo '{"hosting": [{"target": "'$FIREBASE_HOSTING_SITE_ID'", "public": "'$DEPLOY_TARGET_DIR'", "ignore": ["firebase.json", "**/.*", "**/node_modules/**"]}]}' > firebase.json
			else
			  echo "SKIP: firebase hosting site not found"
			fi
			"""
		env: [{
			name:  "GCP_PROJECT_ID"
			value: "$(params.gcpProjectId)"
		}, {
			name:  "DEPLOY_TARGET_DIR"
			value: "$(params.deployTargetDir)"
		}]
	}, {
		image:      "asia-northeast1-docker.pkg.dev/solarray-pro-83383605/valuestream/firebase-tools:\(base.config.firebaseToolsImageTag)"
		name:       "deploy"
		workingDir: "$(workspaces.shared.path)/source/$(params.buildTargetDir)"
		script: """
			#!/usr/bin/env bash
			if [ -e $(workspaces.shared.path)/siteId ]; then
			  FIREBASE_HOSTING_SITE_ID=$(cat $(workspaces.shared.path)/siteId)
			  firebase deploy --only hosting:"${FIREBASE_HOSTING_SITE_ID}"
			else
			  echo "SKIP: firebase hosting site not found"
			fi
			"""
		env: [{
			name:  "GOOGLE_APPLICATION_CREDENTIALS"
			value: "/secret/account.json"
		}]
		volumeMounts: [{
			name:      "user-gcp-secret"
			mountPath: "/secret"
			readOnly:  true
		}]
	}]
	volumes: [{
		name: "user-gcp-secret"
		secret: {
			items: [{
				key:  "serviceaccount"
				path: "account.json"
			}]
			secretName: "$(params.gcpServiceAccountSecretName)"
		}
	}]
}
