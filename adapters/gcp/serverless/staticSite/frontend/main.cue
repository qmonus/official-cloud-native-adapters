package frontend

import (
	"strings"
	"qmonus.net/adapter/official/types:gcp"
	"qmonus.net/adapter/official/types:random"
	publishSite "qmonus.net/adapter/official/pipeline/deploy:gcpFirebaseHosting"
	"qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml"
)

DesignPattern: {
	parameters: {
		appName:                            string
		gcpProjectId:                       string
		gcpFirebaseHostingSiteId:           string
		gcpFirebaseHostingCustomDomainName: strings.HasSuffix(".")
		dnsZoneProjectId:                   string
		dnsZoneName:                        string
		// used for gcpFirebaseHosting pipeline.
		environmentVariables: [string]: string
	}
	pipelineParameters: {
		// common parameters derived from multiple adapters
		repositoryKind: string | *""
		useSshKey:      bool | *false
	}

	composites: [
		{
			pattern: simpleDeployByPulumiYaml.DesignPattern
			pipelineParams: {
				repositoryKind:       pipelineParameters.repositoryKind
				useDebug:             false
				deployPhase:          "app"
				resourcePriority:     "medium"
				useSshKey:            pipelineParameters.useSshKey
				pulumiCredentialName: "qmonus-pulumi-secret"
				useCred: {
					kubernetes: false
					gcp:        true
					aws:        false
					azure:      false
				}
				importStackName: ""
			}
		},
		{
			pattern: publishSite.DesignPattern
			pipelineParams: {
				repositoryKind: pipelineParameters.repositoryKind
				useSshKey:      pipelineParameters.useSshKey
			}
		},
	]

	let _googleCloudProvider = "gcpProvider"
	let _firebaseHostingSite = "firebaseHostingSite"
	let _firebaseHostingCustomDomain = "firebaseHostingCustomDomain"
	let _siteIdSuffix = "siteIdSuffix"
	let _cloudDnsCnameRecord = "cloudDnsCnameRecord"

	parameters: #resourceId: {
		gcpProvider:                 _googleCloudProvider
		firebaseHostingSite:         _firebaseHostingSite
		firebaseHostingCustomDomain: _firebaseHostingCustomDomain
		siteIdSuffix:                _siteIdSuffix
		cloudDnsCnameRecord:         _cloudDnsCnameRecord
	}

	resources: app: {
		_gcpProvider: provider: "${\(_googleCloudProvider)}"

		"\(_googleCloudProvider)": gcp.#GcpProvider & {
			properties: {
				project: parameters.gcpProjectId
			}
		}

		"\(_firebaseHostingSite)": gcp.#FirebaseHostingSite & {
			options: _gcpProvider
			properties: {
				siteId: "\(parameters.gcpFirebaseHostingSiteId)-${\(_siteIdSuffix).result}"
			}
		}

		"\(_firebaseHostingCustomDomain)": gcp.#FirebaseHostingCustomDomain & {
			options: _gcpProvider
			properties: {
				siteId:              "${\(_firebaseHostingSite).siteId}"
				customDomain:        strings.TrimSuffix(parameters.gcpFirebaseHostingCustomDomainName, ".")
				waitDnsVerification: false
			}
		}

		"\(_siteIdSuffix)": random.#RandomString & {
			properties: {
				length:  5
				special: false
				upper:   false
			}
		}

		"\(_cloudDnsCnameRecord)": gcp.#GcpCloudDnsRecordSet & {
			properties: {
				name:        parameters.gcpFirebaseHostingCustomDomainName
				managedZone: parameters.dnsZoneName
				project:     parameters.dnsZoneProjectId
				type:        "CNAME"
				ttl:         3600
				rrdatas: ["${\(_firebaseHostingSite).siteId}.web.app."]
			}
		}
	}

	pipelines: {}
}
