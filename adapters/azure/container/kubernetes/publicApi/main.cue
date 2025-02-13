package publicApi

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/yaml"
	"strings"
	"strconv"
	"list"

	"qmonus.net/adapter/official/adapters/kubernetes/templates"
	"qmonus.net/adapter/official/types:base"
)

DesignPattern: {
	parameters: {
		appName:      string
		k8sNamespace: string
		nodeSelector?: [string]: string
		strategyType:                *"RollingUpdate" | "Recreate"
		rollingUpdateMaxSurge:       string | *"25%"
		rollingUpdateMaxUnavailable: string | *"25%"
		replicas:                    string | *"1"
		imagePullSecret?:            base.#Secret
		b64EncodedImagePullSecret?:  string
		imagePullSecretName?:        string
		// main container params
		imageName: string
		command?: [...string]
		args?: [...string]
		port:                  string
		portName?:             string
		portProtocol:          *"TCP" | "UDP"
		secondaryPort?:        string
		secondaryPortName?:    string
		secondaryPortProtocol: *"TCP" | "UDP"
		env?: [...templates.#env]
		cpuRequest?:      string
		cpuLimit?:        string
		memoryRequest?:   string
		memoryLimit?:     string
		livenessProbe?:   templates.#probe
		readinessProbe?:  templates.#probe
		startupProbe?:    templates.#probe
		volumeMountPath?: string
		// sidecar container params
		sidecarContainerImageName?: string
		sidecarContainerCommand?: [...string]
		sidecarContainerArgs?: [...string]
		sidecarContainerPort?:                 string
		sidecarContainerPortName?:             string
		sidecarContainerPortProtocol:          *"TCP" | "UDP"
		sidecarContainerSecondaryPort?:        string
		sidecarContainerSecondaryPortName?:    string
		sidecarContainerSecondaryPortProtocol: *"TCP" | "UDP"
		sidecarContainerEnv?: [...templates.#env]
		sidecarContainerCpuRequest?:      string
		sidecarContainerCpuLimit?:        string
		sidecarContainerMemoryRequest?:   string
		sidecarContainerMemoryLimit?:     string
		sidecarContainerLivenessProbe?:   templates.#probe
		sidecarContainerReadinessProbe?:  templates.#probe
		sidecarContainerStartupProbe?:    templates.#probe
		sidecarContainerVolumeMountPath?: string
		// init container params
		initContainerImageName?: string
		initContainerCommand?: [...string]
		initContainerArgs?: [...string]
		initContainerEnv?: [...templates.#env]
		initContainerCpuRequest?:    string
		initContainerCpuLimit?:      string
		initContainerMemoryRequest?: string
		initContainerMemoryLimit?:   string

		servicePorts: [...templates.#port]
		useIngress:              "true" | *"false"
		host?:                   string
		tlsSecretCrt?:           base.#Secret
		tlsSecretKey?:           base.#Secret
		b64EncodedTlsSecretCrt?: string
		b64EncodedTlsSecretKey?: string
		tlsSecretName?:          string
		paths: [...templates.#path]
		configMapData?: [string]:                     _
		sidecarContainerConfigMapData?: [string]:     _
		initContainerConfigMapData?: [string]:        _
		b64EncodedSecrets?: [string]:                 _
		b64EncodedSidecarContainerSecrets?: [string]: _
		b64EncodedInitContainerSecrets?: [string]:    _
		deploymentSecrets?: [string]:                 base.#Secret
		sidecarContainerDeploymentSecrets?: [string]: base.#Secret
		initContainerDeploymentSecrets?: [string]:    base.#Secret
		clusterSecretStoreName?: string
		refreshInterval:         string | *"1h"

		podAnnotations?: [string]:     string
		serviceAnnotations?: [string]: string
		ingressAnnotations?: [string]: string

		// parameter validation
		if rollingUpdateMaxSurge == "0" && rollingUpdateMaxUnavailable == "0" ||
			rollingUpdateMaxSurge == "0%" && rollingUpdateMaxUnavailable == "0%" ||
			rollingUpdateMaxSurge == "0" && rollingUpdateMaxUnavailable == "0%" ||
			rollingUpdateMaxSurge == "0%" && rollingUpdateMaxUnavailable == "0" {
			_error: "both rollingUpdateMaxSurge and rollingUpdateMaxUnavailable cannot be set to 0."
			error:  _error & !=_error
		}
	}

	resources: app: {
		"\(parameters.appName)Deployment": templates.k8sDeployment & {
			#name:                        parameters.appName
			#namespace:                   parameters.k8sNamespace
			#nodeSelector:                parameters.nodeSelector
			#strategyType:                parameters.strategyType
			#rollingUpdateMaxSurge:       parameters.rollingUpdateMaxSurge
			#rollingUpdateMaxUnavailable: parameters.rollingUpdateMaxUnavailable
			#replicas:                    parameters.replicas
			#container: {
				imageName:             parameters.imageName
				command:               parameters.command
				args:                  parameters.args
				port:                  parameters.port
				portName:              parameters.portName
				portProtocol:          parameters.portProtocol
				secondaryPort:         parameters.secondaryPort
				secondaryPortName:     parameters.secondaryPortName
				secondaryPortProtocol: parameters.secondaryPortProtocol
				env:                   parameters.env
				cpuRequest:            parameters.cpuRequest
				memoryRequest:         parameters.memoryRequest
				cpuLimit:              parameters.cpuLimit
				memoryLimit:           parameters.memoryLimit
				livenessProbe:         parameters.livenessProbe
				readinessProbe:        parameters.readinessProbe
				startupProbe:          parameters.startupProbe
				volumeMountPath:       parameters.volumeMountPath
			}
			#sidecarContainer: {
				imageName:             parameters.sidecarContainerImageName
				command:               parameters.sidecarContainerCommand
				args:                  parameters.sidecarContainerArgs
				port:                  parameters.sidecarContainerPort
				portName:              parameters.sidecarContainerPortName
				portProtocol:          parameters.sidecarContainerPortProtocol
				secondaryPort:         parameters.sidecarContainerSecondaryPort
				secondaryPortName:     parameters.sidecarContainerSecondaryPortName
				secondaryPortProtocol: parameters.sidecarContainerSecondaryPortProtocol
				env:                   parameters.sidecarContainerEnv
				cpuRequest:            parameters.sidecarContainerCpuRequest
				memoryRequest:         parameters.sidecarContainerMemoryRequest
				cpuLimit:              parameters.sidecarContainerCpuLimit
				memoryLimit:           parameters.sidecarContainerMemoryLimit
				livenessProbe:         parameters.sidecarContainerLivenessProbe
				readinessProbe:        parameters.sidecarContainerReadinessProbe
				startupProbe:          parameters.sidecarContainerStartupProbe
				volumeMountPath:       parameters.sidecarContainerVolumeMountPath
			}
			#initContainer: {
				imageName:     parameters.initContainerImageName
				command:       parameters.initContainerCommand
				args:          parameters.initContainerArgs
				env:           parameters.initContainerEnv
				cpuRequest:    parameters.initContainerCpuRequest
				memoryRequest: parameters.initContainerMemoryRequest
				cpuLimit:      parameters.initContainerCpuLimit
				memoryLimit:   parameters.initContainerMemoryLimit
			}

			// To avoid cycle errors in the annotations field
			if parameters.podAnnotations != _|_ {
				#podAnnotations: parameters.podAnnotations
			}
		}
		"\(parameters.appName)Service": templates.k8sService & {
			#name:      parameters.appName
			#namespace: parameters.k8sNamespace
			#ports:     parameters.servicePorts

			// To avoid cycle errors in the annotations field
			if parameters.serviceAnnotations != _|_ {
				#annotations: parameters.serviceAnnotations
			}
		}
		let _useIngress = strconv.ParseBool(parameters.useIngress)
		if _useIngress {
			"\(parameters.appName)Ingress": templates.k8sIngressForAzure & {
				#name:      parameters.appName
				#namespace: parameters.k8sNamespace
				#host:      parameters.host
				#paths:     parameters.paths

				// To avoid cycle errors in the annotations field
				if parameters.ingressAnnotations != _|_ {
					#annotations: parameters.ingressAnnotations
				}
			}
		}

		_configMapDependsOn:      string | *""
		_externalSecretDependsOn: string | *""
		_secretDependsOn:         string | *""

		_sidecarContainerConfigMapDependsOn:      string | *""
		_sidecarContainerExternalSecretDependsOn: string | *""
		_sidecarContainerSecretDependsOn:         string | *""

		_initContainerConfigMapDependsOn:      string | *""
		_initContainerExternalSecretDependsOn: string | *""
		_initContainerSecretDependsOn:         string | *""

		_externalSecretIpsDependsOn: string | *""
		_secretIpsDependsOn:         string | *""

		_externalSecretTlsDependsOn: string | *""
		_secretTlsDependsOn:         string | *""

		if parameters.configMapData != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.configMapData {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {"\(k)": parameters.configMapData["\(k)"]}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)
			"\(parameters.appName)ConfigMap": templates.k8sConfigMap & {
				#name:      "\(parameters.appName)-\(_hash)"
				#namespace: parameters.k8sNamespace
				#data:      parameters.configMapData
			}

			"\(parameters.appName)Deployment": #container: configMapName: "\(parameters.appName)-\(_hash)"
			_configMapDependsOn: "core:ConfigMap::\(parameters.k8sNamespace)/\(parameters.appName)-\(_hash),"
		}

		if parameters.deploymentSecrets != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.deploymentSecrets {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {
				"\(k)": {
					key:     parameters.deploymentSecrets["\(k)"].key
					version: parameters.deploymentSecrets["\(k)"].version
				}
			}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)ExternalSecret": templates.k8sExternalSecret & {
				#name:                   "\(parameters.appName)-\(_hash)"
				#namespace:              parameters.k8sNamespace
				#secrets:                parameters.deploymentSecrets
				#clusterSecretStoreName: parameters.clusterSecretStoreName
				#refreshInterval:        parameters.refreshInterval
			}

			"\(parameters.appName)Deployment": #container: secretName: "\(parameters.appName)-\(_hash)"
			_externalSecretDependsOn: "external-secrets.io:ExternalSecret::\(parameters.k8sNamespace)/\(parameters.appName)-\(_hash),"
		}

		if parameters.b64EncodedSecrets != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.b64EncodedSecrets {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {"\(k)": parameters.b64EncodedSecrets["\(k)"]}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)Secret": templates.k8sSecret & {
				#name:      "\(parameters.appName)-\(_hash)"
				#namespace: parameters.k8sNamespace
				#secrets:   parameters.b64EncodedSecrets
			}

			"\(parameters.appName)Deployment": #container: secretName: "\(parameters.appName)-\(_hash)"
			_secretDependsOn: "core:Secret::\(parameters.k8sNamespace)/\(parameters.appName)-\(_hash),"
		}

		if parameters.sidecarContainerConfigMapData != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.sidecarContainerConfigMapData {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {"\(k)": parameters.sidecarContainerConfigMapData["\(k)"]}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)
			"\(parameters.appName)ConfigMapForSidecar": templates.k8sConfigMap & {
				#name:      "\(parameters.appName)-sidecar-\(_hash)"
				#namespace: parameters.k8sNamespace
				#data:      parameters.sidecarContainerConfigMapData
			}

			"\(parameters.appName)Deployment": #sidecarContainer: configMapName: "\(parameters.appName)-sidecar-\(_hash)"
			_sidecarContainerConfigMapDependsOn: "core:ConfigMap::\(parameters.k8sNamespace)/\(parameters.appName)-sidecar-\(_hash),"
		}

		if parameters.sidecarContainerDeploymentSecrets != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.sidecarContainerDeploymentSecrets {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {
				"\(k)": {
					key:     parameters.sidecarContainerDeploymentSecrets["\(k)"].key
					version: parameters.sidecarContainerDeploymentSecrets["\(k)"].version
				}
			}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)ExternalSecretForSidecar": templates.k8sExternalSecret & {
				#name:                   "\(parameters.appName)-sidecar-\(_hash)"
				#namespace:              parameters.k8sNamespace
				#secrets:                parameters.sidecarContainerDeploymentSecrets
				#clusterSecretStoreName: parameters.clusterSecretStoreName
				#refreshInterval:        parameters.refreshInterval
			}

			"\(parameters.appName)Deployment": #sidecarContainer: secretName: "\(parameters.appName)-sidecar-\(_hash)"
			_sidecarContainerExternalSecretDependsOn: "external-secrets.io:ExternalSecret::\(parameters.k8sNamespace)/\(parameters.appName)-sidecar-\(_hash),"
		}

		if parameters.b64EncodedSidecarContainerSecrets != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.b64EncodedSidecarContainerSecrets {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {"\(k)": parameters.b64EncodedSidecarContainerSecrets["\(k)"]}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)SecretForSidecar": templates.k8sSecret & {
				#name:      "\(parameters.appName)-sidecar-\(_hash)"
				#namespace: parameters.k8sNamespace
				#secrets:   parameters.b64EncodedSidecarContainerSecrets
			}

			"\(parameters.appName)Deployment": #sidecarContainer: secretName: "\(parameters.appName)-sidecar-\(_hash)"
			_sidecarContainerSecretDependsOn: "core:Secret::\(parameters.k8sNamespace)/\(parameters.appName)-sidecar-\(_hash),"
		}

		if parameters.initContainerConfigMapData != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.initContainerConfigMapData {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {"\(k)": parameters.initContainerConfigMapData["\(k)"]}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)
			"\(parameters.appName)ConfigMapForInitContainer": templates.k8sConfigMap & {
				#name:      "\(parameters.appName)-init-\(_hash)"
				#namespace: parameters.k8sNamespace
				#data:      parameters.initContainerConfigMapData
			}

			"\(parameters.appName)Deployment": #initContainer: configMapName: "\(parameters.appName)-init-\(_hash)"
			_initContainerConfigMapDependsOn: "core:ConfigMap::\(parameters.k8sNamespace)/\(parameters.appName)-init-\(_hash),"
		}

		if parameters.initContainerDeploymentSecrets != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.initContainerDeploymentSecrets {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {
				"\(k)": {
					key:     parameters.initContainerDeploymentSecrets["\(k)"].key
					version: parameters.initContainerDeploymentSecrets["\(k)"].version
				}
			}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)ExternalSecretForInitContainer": templates.k8sExternalSecret & {
				#name:                   "\(parameters.appName)-init-\(_hash)"
				#namespace:              parameters.k8sNamespace
				#secrets:                parameters.initContainerDeploymentSecrets
				#clusterSecretStoreName: parameters.clusterSecretStoreName
				#refreshInterval:        parameters.refreshInterval
			}

			"\(parameters.appName)Deployment": #initContainer: secretName: "\(parameters.appName)-init-\(_hash)"
			_initContainerExternalSecretDependsOn: "external-secrets.io:ExternalSecret::\(parameters.k8sNamespace)/\(parameters.appName)-init-\(_hash),"
		}

		if parameters.b64EncodedInitContainerSecrets != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _unsortKeys = [ for k, v in parameters.b64EncodedInitContainerSecrets {k}]
			let _sortedKeys = list.Sort(_unsortKeys, list.Ascending)
			let _sortedData = {for k in _sortedKeys {"\(k)": parameters.b64EncodedInitContainerSecrets["\(k)"]}}
			let _data = yaml.Marshal(_sortedData)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)SecretForInitContainer": templates.k8sSecret & {
				#name:      "\(parameters.appName)-init-\(_hash)"
				#namespace: parameters.k8sNamespace
				#secrets:   parameters.b64EncodedInitContainerSecrets
			}

			"\(parameters.appName)Deployment": #initContainer: secretName: "\(parameters.appName)-init-\(_hash)"
			_initContainerSecretDependsOn: "core:Secret::\(parameters.k8sNamespace)/\(parameters.appName)-init-\(_hash),"
		}

		if parameters.imagePullSecret != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _secrets = {
				"dockerconfigjson": {
					key:     parameters.imagePullSecret.key
					version: parameters.imagePullSecret.version
				}
			}
			let _data = yaml.Marshal(_secrets)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)ExternalSecretIps": templates.k8sExternalSecret & {
				#name:                   "\(parameters.appName)-ips-\(_hash)"
				#namespace:              parameters.k8sNamespace
				#secrets:                _secrets
				#clusterSecretStoreName: parameters.clusterSecretStoreName
				#refreshInterval:        parameters.refreshInterval
				#type:                   "kubernetes.io/dockerconfigjson"
			}

			"\(parameters.appName)Deployment": #imagePullSecretName: "\(parameters.appName)-ips-\(_hash)"
			_externalSecretIpsDependsOn: "external-secrets.io:ExternalSecret::\(parameters.k8sNamespace)/\(parameters.appName)-ips-\(_hash),"
		}

		if parameters.b64EncodedImagePullSecret != _|_ {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _secrets = {
				".dockerconfigjson": parameters.b64EncodedImagePullSecret
			}
			let _data = yaml.Marshal(_secrets)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)SecretIps": templates.k8sSecret & {
				#name:      "\(parameters.appName)-ips-\(_hash)"
				#namespace: parameters.k8sNamespace
				#secrets:   _secrets
				#type:      "kubernetes.io/dockerconfigjson"
			}

			"\(parameters.appName)Deployment": #imagePullSecretName: "\(parameters.appName)-ips-\(_hash)"
			_secretIpsDependsOn: "core:Secret::\(parameters.k8sNamespace)/\(parameters.appName)-ips-\(_hash),"
		}

		if parameters.tlsSecretCrt != _|_ && parameters.tlsSecretKey != _|_ && _useIngress {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _secrets = {
				tlsCrt: {
					key:     parameters.tlsSecretCrt.key
					version: parameters.tlsSecretCrt.version
				}
				tlsKey: {
					key:     parameters.tlsSecretKey.key
					version: parameters.tlsSecretKey.version
				}
			}
			let _data = yaml.Marshal(_secrets)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)ExternalSecretTls": templates.k8sExternalSecret & {
				#name:                   "\(parameters.appName)-tls-\(_hash)"
				#namespace:              parameters.k8sNamespace
				#secrets:                _secrets
				#clusterSecretStoreName: parameters.clusterSecretStoreName
				#refreshInterval:        parameters.refreshInterval
				#type:                   "kubernetes.io/tls"
			}

			"\(parameters.appName)Ingress": #tlsSecretName: "\(parameters.appName)-tls-\(_hash)"
			_externalSecretTlsDependsOn: "external-secrets.io:ExternalSecret::\(parameters.k8sNamespace)/\(parameters.appName)-tls-\(_hash),"
		}

		if parameters.b64EncodedTlsSecretCrt != _|_ && parameters.b64EncodedTlsSecretKey != _|_ && _useIngress {
			// ref: https://docs.valuestream.qmonus.net/spec/cloud-native-adapter/tips.html#secret%E3%81%A8configmap%E3%81%AE%E6%9B%B4%E6%96%B0%E3%81%AB%E8%BF%BD%E5%BE%93%E3%81%97%E3%81%9Fdeployment%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%AE%9A%E7%BE%A9
			let _secrets = {
				"tls.crt": parameters.b64EncodedTlsSecretCrt
				"tls.key": parameters.b64EncodedTlsSecretKey
			}
			let _data = yaml.Marshal(_secrets)
			let _hash = strings.SliceRunes(hex.Encode(sha256.Sum256(_data)), 0, 10)

			"\(parameters.appName)SecretTls": templates.k8sSecret & {
				#name:      "\(parameters.appName)-tls-\(_hash)"
				#namespace: parameters.k8sNamespace
				#secrets:   _secrets
				#type:      "kubernetes.io/tls"
			}

			"\(parameters.appName)Ingress": #tlsSecretName: "\(parameters.appName)-tls-\(_hash)"
			_secretTlsDependsOn: "core:Secret::\(parameters.k8sNamespace)/\(parameters.appName)-tls-\(_hash),"
		}

		_dependsOn: strings.Trim(
				_configMapDependsOn+
			_externalSecretDependsOn+
			_secretDependsOn+
			_sidecarContainerConfigMapDependsOn+
			_sidecarContainerExternalSecretDependsOn+
			_sidecarContainerSecretDependsOn+
			_initContainerConfigMapDependsOn+
			_initContainerExternalSecretDependsOn+
			_initContainerSecretDependsOn+
			_externalSecretIpsDependsOn+
			_secretIpsDependsOn+
			_externalSecretTlsDependsOn+
			_secretTlsDependsOn, ",")

		if _dependsOn != "" {
			"\(parameters.appName)Deployment": #annotations: "vs.axis-dev.io/dependsOn": _dependsOn
		}

		if parameters.imagePullSecretName != _|_ {
			"\(parameters.appName)Deployment": #imagePullSecretName: parameters.imagePullSecretName
		}

		if parameters.tlsSecretName != _|_ {
			"\(parameters.appName)Ingress": #tlsSecretName: parameters.tlsSecretName
		}
	}
}
