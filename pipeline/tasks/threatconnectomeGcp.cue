package threatconnectomeGcp

import (
	"qmonus.net/adapter/official/pipeline/schema"
)

let _vars = {
	outputDir:  "$(workspaces.shared.path)/scan"
	workingDir: "$(workspaces.shared.path)"
	threatconnectome: {
		endpoint: "https://api.threatconnectome.metemcyber.ntt.com"
		script:   "https://storage.googleapis.com/metemcyber/trivy_tags.py"
	}
}
#BuildInput: {
	groupName: string | *""
	...
}
#Builder: schema.#TaskBuilder & {
	name:  "threatconnectome"
	input: #BuildInput
	params: {
		threatconnectomeTeamUUID: desc:         "Threatconnectome Product Team UUID"
		threatconnectomeRefreshTokenName: desc: "Secret Name for Threatconnectome Refresh Token"
		imageRegistryPath: desc:                "Path of the container registry without image name"
		imageShortName: desc:                   "Short name of the image"
		imageTag: desc:                         "Image tag"
		gcpServiceAccountSecretName: desc:      "Secret Name of GCP SA Credential"
	}
	workspaces: [{
		name: "shared"
	}]
	steps: [
		#StepScanSetup,
		#StepTrivyScan,
		#StepDownloadScript,
		#StepTransformTrivyResult,
		{
			#StepUploadArtifactTags
			#input: input
		},
	]

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

#StepScanSetup: {
	name:   "scan-setup"
	image:  "bash"
	script: """
		#!/usr/bin/env bash
		set -o nounset
		set -o xtrace
		set -o pipefail
		mkdir -p \(_vars.outputDir)
		"""
}

#StepTrivyScan: {
	name:  "trivy-image-scan"
	image: "aquasec/trivy:0.36.1"
	args: [
		"image",
		"--no-progress",
		"--list-all-pkgs",
		"--exit-code",
		"0",
		"--security-checks",
		"vuln",
		"--format",
		"json",
		"--output",
		"\(_vars.outputDir)/trivy-result.json",
		"$(params.imageRegistryPath)/$(params.imageShortName):$(params.imageTag)",
	]
	env: [{
		name:  "GOOGLE_APPLICATION_CREDENTIALS"
		value: "/secret/account.json"
	}]
	volumeMounts: [{
		name:      "user-gcp-secret"
		mountPath: "/secret"
		readOnly:  true
	}]
	resources: {
		requests: {
			cpu:    "0.5"
			memory: "512Mi"
		}
		limits: {
			cpu:    "0.5"
			memory: "512Mi"
		}
	}
}

#StepDownloadScript: {
	name:  "download-script"
	image: "gcr.io/cloud-builders/wget"
	args: [
		"-O",
		"\(_vars.workingDir)/trivy_tags.py",
		_vars.threatconnectome.script,
	]
}

#StepTransformTrivyResult: {
	name:  "transform-trivy-result"
	image: "python:3.10"
	args: [
		"\(_vars.workingDir)/trivy_tags.py",
		"-i",
		"\(_vars.outputDir)/trivy-result.json",
		"-o",
		"\(_vars.outputDir)/artifact_tags.jsonl",
	]
	resources: {
		requests: {
			cpu:    "0.5"
			memory: "512Mi"
		}
		limits: {
			cpu:    "0.5"
			memory: "512Mi"
		}
	}
}

#StepUploadArtifactTags: {
	#input: #BuildInput
	name:   "upload-artifact-tags"
	image:  "python:3.10"
	script: _script
	args: [
		"--team", "$(params.threatconnectomeTeamUUID)",
		"--group",
		if #input.groupName == "" {
			"$(params.imageShortName)"
		},
		if #input.groupName != "" {
			"\(#input.groupName)"
		},
		"--input", "\(_vars.outputDir)/artifact_tags.jsonl",
		"--endpoint", _vars.threatconnectome.endpoint,
	]
	env: [{
		name: "THREATCONNECTOME_REFRESH_TOKEN"
		valueFrom: secretKeyRef: {
			name: "$(params.threatconnectomeRefreshTokenName)"
			key:  "refresh_token"
		}
	}]
}

// Python implementation of https://storage.googleapis.com/metemcyber/sbom_registration.yml
let _script = ###"""
	#!/usr/bin/env python3

	import os
	import json
	import urllib.parse
	import urllib.request
	import argparse

	FORM_BOUNDARY = "----QmonusVSFormBoundary"


	def get_access_token(endpoint):
		REFRESH_TOKEN = os.environ.get("THREATCONNECTOME_REFRESH_TOKEN", "")
		if REFRESH_TOKEN == "":
			raise Exception("THREATCONNECTOME_REFRESH_TOKEN must be set")

		data = {"refresh_token": REFRESH_TOKEN}
		req = urllib.request.Request(
			urllib.parse.urljoin(endpoint, "auth/refresh"),
			json.dumps(data).encode("ascii"),
			{"Content-Type": "application/json"}
		)
		try:
			with urllib.request.urlopen(req) as resp:
				data = json.loads(resp.read())
				access_token = data["access_token"]
				print("Successfuly got an access token")
		except urllib.error.HTTPError as err:
			print(err.status, err.reason, err.read().decode())
			raise err
		except urllib.error.URLError as err:
			print(err.reason)
			raise err
		return access_token


	def multipart_formdata(text):
		lines = []
		lines.append("--" + FORM_BOUNDARY)
		lines.append(
			'Content-Disposition: form-data; name="file"; filename="artifact_tags.jsonl"'
		)
		lines.append("Content-Type: application/octet-stream")
		lines.append("")
		lines.append(text)
		lines.append("--" + FORM_BOUNDARY + "--")
		lines.append("")
		return "\r\n".join(lines)


	def upload_artifact_tags(team, group, input, endpoint, access_token):
		url = urllib.parse.urljoin(
			endpoint,
			"pteams/{}/upload_tags_file?group={}&force_mode=True".format(
				urllib.parse.quote(team), urllib.parse.quote(group)
			),
		)
		with open(input, "r") as f:
			data = multipart_formdata(f.read())
		headers = {
			"Content-Type": f"multipart/form-data; boundary={FORM_BOUNDARY};",
			"Authorization": f"Bearer {access_token}",
		}
		req = urllib.request.Request(url, data.encode("ascii"), headers)
		try:
			with urllib.request.urlopen(req) as resp:
				print("Total {} tags were uploaded".format(len(resp.read())))
		except urllib.error.HTTPError as err:
			print(err.status, err.reason, err.read().decode())
			raise err
		except urllib.error.URLError as err:
			print(err.reason)
			raise err


	if __name__ == "__main__":
		parser = argparse.ArgumentParser(
			description='Upload artifact tags on Threatconnectome')
		parser.add_argument('-t', '--team', metavar="UUID", type=str, required=True,
							help='Threatconnectome product team uuid')
		parser.add_argument('-g', '--group', metavar="NAME", type=str, required=True,
							help='Name of repository or product')
		parser.add_argument('-i', "--input", metavar="PATH", type=str, required=True,
							help='Path to artifact tags file')
		parser.add_argument('--endpoint', metavar="URL", type=str,
							help='Threatconnectome api endpoint url')
		args = parser.parse_args()

		access_token = get_access_token(args.endpoint)
		upload_artifact_tags(args.team, args.group, args.input,
					args.endpoint, access_token)
	"""###
