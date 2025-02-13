package templates

import (
	"strconv"

	"qmonus.net/adapter/official/kubernetes:types"
)

let _emptyDirName = "empty-dir"

#containerSchema: {
	imageName: string
	command: [...string]
	args: [...string]
	port:                  string
	portName:              string
	portProtocol:          *"TCP" | "UDP"
	secondaryPort:         string
	secondaryPortName:     string
	secondaryPortProtocol: *"TCP" | "UDP"
	env: [...#env]
	cpuRequest:      string
	cpuLimit:        string
	memoryRequest:   string
	memoryLimit:     string
	livenessProbe:   #probe
	readinessProbe:  #probe
	startupProbe:    #probe
	configMapName:   string
	secretName:      string
	volumeMountPath: string
}

#env: {
	name:  string
	value: _
}

#probe: {
	exec?: {
		command: [...string]
	}
	httpGet?: {
		host?: string
		httpHeaders?: [...{
			name:  string
			value: string
		}]
		path:    string
		port:    string
		scheme?: string
	}
	tcpSocket?: {
		host?: string
		port:  string
	}
	if exec != _|_ && httpGet != _|_ ||
		exec != _|_ && tcpSocket != _|_ ||
		httpGet != _|_ && tcpSocket != _|_ {
		_error: "only one of exec, httpGet, or tcpSocket can be used as a probe type."
		error:  _error & !=_error
	}
	failureThreshold?:    string
	initialDelaySeconds?: string
	periodSeconds?:       string
	successThreshold?:    string
	timeoutSeconds?:      string
}

k8sDeployment: types.#Deployment & {
	#name:      string
	#namespace: string
	#annotations: [string]:    string
	#podAnnotations: [string]: string
	#nodeSelector: [string]:   string
	#strategyType:                *"RollingUpdate" | "Recreate"
	#rollingUpdateMaxSurge:       string | *"25%"
	#rollingUpdateMaxUnavailable: string | *"25%"
	#replicas:                    string | *"1"
	#imagePullSecretName:         string
	#container:                   #containerSchema
	#initContainer:               #containerSchema
	#sidecarContainer:            #containerSchema

	metadata: {
		name:      #name
		namespace: #namespace
		// add len condition to avoid generating empty annotations field
		if #annotations != _|_ && len(#annotations) > 0 {
			annotations: #annotations
		}
	}
	spec: {
		replicas: strconv.Atoi(#replicas)
		selector: matchLabels: app: #name
		strategy: {
			type: #strategyType
			if #strategyType == "RollingUpdate" {
				rollingUpdate: {
					if #rollingUpdateMaxSurge =~ "%$" {
						maxSurge: #rollingUpdateMaxSurge
					}
					if #rollingUpdateMaxSurge !~ "%$" {
						maxSurge: strconv.Atoi(#rollingUpdateMaxSurge)
					}
					if #rollingUpdateMaxUnavailable =~ "%$" {
						maxUnavailable: #rollingUpdateMaxUnavailable
					}
					if #rollingUpdateMaxUnavailable !~ "%$" {
						maxUnavailable: strconv.Atoi(#rollingUpdateMaxUnavailable)
					}
				}
			}
		}
		template: {
			metadata: {
				labels: app: #name
				// add len condition to avoid generating empty annotations field
				if #podAnnotations != _|_ && len(#podAnnotations) > 0 {
					annotations: #podAnnotations
				}
			}
			spec: {
				if #nodeSelector != _|_ {
					nodeSelector: #nodeSelector
				}
				if #initContainer.imageName != _|_ {
					initContainers: [
						_initContainer,
					]
				}
				containers: [
					_container,
					if #sidecarContainer.imageName != _|_ {
						_sidecarContainer
					},
				]
				if #imagePullSecretName != _|_ {
					imagePullSecrets: [{
						name: #imagePullSecretName
					}]
				}
				if #container.volumeMountPath != _|_ || #sidecarContainer.volumeMountPath != _|_ {
					volumes: [{
						name: _emptyDirName
						emptyDir: {}
					}]
				}
			}
		}

		_initContainer: {
			name:  "\(#name)-init"
			image: #initContainer.imageName
			if #initContainer.command != _|_ {
				command: #initContainer.command
			}
			if #initContainer.args != _|_ {
				args: #initContainer.args
			}
			if #initContainer.cpuRequest != _|_ {
				resources: requests: cpu: #initContainer.cpuRequest
			}
			if #initContainer.memoryRequest != _|_ {
				resources: requests: memory: #initContainer.memoryRequest
			}
			if #initContainer.cpuLimit != _|_ {
				resources: limits: cpu: #initContainer.cpuLimit
			}
			if #initContainer.memoryLimit != _|_ {
				resources: limits: memory: #initContainer.memoryLimit
			}
			if #initContainer.env != _|_ {
				env: #initContainer.env
			}
			if #initContainer.configMapName != _|_ || #initContainer.secretName != _|_ {
				envFrom: [
					if #initContainer.configMapName != _|_ {
						configMapRef: name: #initContainer.configMapName
					},
					if #initContainer.secretName != _|_ {
						secretRef: name: #initContainer.secretName
					},
				]
			}
		}

		_container: {
			name:  #name
			image: #container.imageName
			if #container.command != _|_ {
				command: #container.command
			}
			if #container.args != _|_ {
				args: #container.args
			}
			ports: [
				{
					containerPort: strconv.Atoi(#container.port)
					protocol:      #container.portProtocol
					if #container.portName != _|_ {
						name: #container.portName
					}
				},
				if #container.secondaryPort != _|_ {
					containerPort: strconv.Atoi(#container.secondaryPort)
					protocol:      #container.secondaryPortProtocol
					if #container.secondaryPortName != _|_ {
						name: #container.secondaryPortName
					}
				},
			]
			if #container.cpuRequest != _|_ {
				resources: requests: cpu: #container.cpuRequest
			}
			if #container.memoryRequest != _|_ {
				resources: requests: memory: #container.memoryRequest
			}
			if #container.cpuLimit != _|_ {
				resources: limits: cpu: #container.cpuLimit
			}
			if #container.memoryLimit != _|_ {
				resources: limits: memory: #container.memoryLimit
			}
			if #container.env != _|_ {
				env: #container.env
			}
			if #container.configMapName != _|_ || #container.secretName != _|_ {
				envFrom: [
					if #container.configMapName != _|_ {
						configMapRef: name: #container.configMapName
					},
					if #container.secretName != _|_ {
						secretRef: name: #container.secretName
					},
				]
			}
			if #container.livenessProbe != _|_ {
				livenessProbe: _livenessProbe
			}
			if #container.readinessProbe != _|_ {
				readinessProbe: _readinessProbe
			}
			if #container.startupProbe != _|_ {
				startupProbe: _startupProbe
			}
			if #container.volumeMountPath != _|_ {
				volumeMounts: [{
					name:      _emptyDirName
					mountPath: #container.volumeMountPath
				}]
			}
		}

		_sidecarContainer: {
			name:  "\(#name)-sidecar"
			image: #sidecarContainer.imageName
			if #sidecarContainer.command != _|_ {
				command: #sidecarContainer.command
			}
			if #sidecarContainer.args != _|_ {
				args: #sidecarContainer.args
			}
			if #sidecarContainer.port != _|_ {
				ports: [
					{
						containerPort: strconv.Atoi(#sidecarContainer.port)
						protocol:      #sidecarContainer.portProtocol
						if #sidecarContainer.portName != _|_ {
							name: #sidecarContainer.portName
						}
					},
					if #container.secondaryPort != _|_ {
						containerPort: strconv.Atoi(#sidecarContainer.secondaryPort)
						protocol:      #sidecarContainer.secondaryPortProtocol
						if #sidecarContainer.secondaryPortName != _|_ {
							name: #sidecarContainer.secondaryPortName
						}
					},
				]
			}
			if #sidecarContainer.cpuRequest != _|_ {
				resources: requests: cpu: #sidecarContainer.cpuRequest
			}
			if #sidecarContainer.memoryRequest != _|_ {
				resources: requests: memory: #sidecarContainer.memoryRequest
			}
			if #sidecarContainer.cpuLimit != _|_ {
				resources: limits: cpu: #sidecarContainer.cpuLimit
			}
			if #sidecarContainer.memoryLimit != _|_ {
				resources: limits: memory: #sidecarContainer.memoryLimit
			}
			if #sidecarContainer.env != _|_ {
				env: #sidecarContainer.env
			}
			if #sidecarContainer.configMapName != _|_ || #sidecarContainer.secretName != _|_ {
				envFrom: [
					if #sidecarContainer.configMapName != _|_ {
						configMapRef: name: #sidecarContainer.configMapName
					},
					if #sidecarContainer.secretName != _|_ {
						secretRef: name: #sidecarContainer.secretName
					},
				]
			}
			if #sidecarContainer.livenessProbe != _|_ {
				livenessProbe: _sidecarContainerLivenessProbe
			}
			if #sidecarContainer.readinessProbe != _|_ {
				readinessProbe: _sidecarContainerReadinessProbe
			}
			if #sidecarContainer.startupProbe != _|_ {
				startupProbe: _sidecarContainerStartupProbe
			}
			if #sidecarContainer.volumeMountPath != _|_ {
				volumeMounts: [{
					name:      _emptyDirName
					mountPath: #sidecarContainer.volumeMountPath
				}]
			}
		}

		_livenessProbe: {
			_probe: #container.livenessProbe
			if _probe.exec != _|_ {
				exec: command: _probe.exec.command
			}
			if _probe.httpGet != _|_ {
				httpGet: {
					path: _probe.httpGet.path
					if _probe.httpGet.port !~ "^[0-9]+$" {
						port: _probe.httpGet.port
					}
					if _probe.httpGet.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.httpGet.port)
					}
					if _probe.httpGet.host != _|_ {
						host: _probe.httpGet.host
					}
					if _probe.httpGet.httpHeaders != _|_ {
						httpHeaders: _probe.httpGet.httpHeaders
					}
					if _probe.httpGet.scheme != _|_ {
						scheme: _probe.httpGet.scheme
					}
				}
			}
			if _probe.tcpSocket != _|_ {
				tcpSocket: {
					if _probe.tcpSocket.port !~ "^[0-9]+$" {
						port: _probe.tcpSocket.port
					}
					if _probe.tcpSocket.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.tcpSocket.port)
					}
					if _probe.tcpSocket.host != _|_ {
						host: _probe.tcpSocket.host
					}
				}
			}
			if _probe.failureThreshold != _|_ {
				failureThreshold: strconv.Atoi(_probe.failureThreshold)
			}
			if _probe.initialDelaySeconds != _|_ {
				initialDelaySeconds: strconv.Atoi(_probe.initialDelaySeconds)
			}
			if _probe.periodSeconds != _|_ {
				periodSeconds: strconv.Atoi(_probe.periodSeconds)
			}
			if _probe.successThreshold != _|_ {
				successThreshold: strconv.Atoi(_probe.successThreshold)
			}
			if _probe.terminationGracePeriodSeconds != _|_ {
				terminationGracePeriodSeconds: strconv.Atoi(_probe.terminationGracePeriodSeconds)
			}
			if _probe.timeoutSeconds != _|_ {
				timeoutSeconds: strconv.Atoi(_probe.timeoutSeconds)
			}
		}

		_readinessProbe: {
			_probe: #container.readinessProbe
			if _probe.exec != _|_ {
				exec: command: _probe.exec.command
			}
			if _probe.httpGet != _|_ {
				httpGet: {
					path: _probe.httpGet.path
					if _probe.httpGet.port !~ "^[0-9]+$" {
						port: _probe.httpGet.port
					}
					if _probe.httpGet.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.httpGet.port)
					}
					if _probe.httpGet.host != _|_ {
						host: _probe.httpGet.host
					}
					if _probe.httpGet.httpHeaders != _|_ {
						httpHeaders: _probe.httpGet.httpHeaders
					}
					if _probe.httpGet.scheme != _|_ {
						scheme: _probe.httpGet.scheme
					}
				}
			}
			if _probe.tcpSocket != _|_ {
				tcpSocket: {
					if _probe.tcpSocket.port !~ "^[0-9]+$" {
						port: _probe.tcpSocket.port
					}
					if _probe.tcpSocket.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.tcpSocket.port)
					}
					if _probe.tcpSocket.host != _|_ {
						host: _probe.tcpSocket.host
					}
				}
			}
			if _probe.failureThreshold != _|_ {
				failureThreshold: strconv.Atoi(_probe.failureThreshold)
			}
			if _probe.initialDelaySeconds != _|_ {
				initialDelaySeconds: strconv.Atoi(_probe.initialDelaySeconds)
			}
			if _probe.periodSeconds != _|_ {
				periodSeconds: strconv.Atoi(_probe.periodSeconds)
			}
			if _probe.successThreshold != _|_ {
				successThreshold: strconv.Atoi(_probe.successThreshold)
			}
			if _probe.terminationGracePeriodSeconds != _|_ {
				terminationGracePeriodSeconds: strconv.Atoi(_probe.terminationGracePeriodSeconds)
			}
			if _probe.timeoutSeconds != _|_ {
				timeoutSeconds: strconv.Atoi(_probe.timeoutSeconds)
			}
		}

		_startupProbe: {
			_probe: #container.startupProbe
			if _probe.exec != _|_ {
				exec: command: _probe.exec.command
			}
			if _probe.httpGet != _|_ {
				httpGet: {
					path: _probe.httpGet.path
					if _probe.httpGet.port !~ "^[0-9]+$" {
						port: _probe.httpGet.port
					}
					if _probe.httpGet.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.httpGet.port)
					}
					if _probe.httpGet.host != _|_ {
						host: _probe.httpGet.host
					}
					if _probe.httpGet.httpHeaders != _|_ {
						httpHeaders: _probe.httpGet.httpHeaders
					}
					if _probe.httpGet.scheme != _|_ {
						scheme: _probe.httpGet.scheme
					}
				}
			}
			if _probe.tcpSocket != _|_ {
				tcpSocket: {
					if _probe.tcpSocket.port !~ "^[0-9]+$" {
						port: _probe.tcpSocket.port
					}
					if _probe.tcpSocket.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.tcpSocket.port)
					}
					if _probe.tcpSocket.host != _|_ {
						host: _probe.tcpSocket.host
					}
				}
			}
			if _probe.failureThreshold != _|_ {
				failureThreshold: strconv.Atoi(_probe.failureThreshold)
			}
			if _probe.initialDelaySeconds != _|_ {
				initialDelaySeconds: strconv.Atoi(_probe.initialDelaySeconds)
			}
			if _probe.periodSeconds != _|_ {
				periodSeconds: strconv.Atoi(_probe.periodSeconds)
			}
			if _probe.successThreshold != _|_ {
				successThreshold: strconv.Atoi(_probe.successThreshold)
			}
			if _probe.terminationGracePeriodSeconds != _|_ {
				terminationGracePeriodSeconds: strconv.Atoi(_probe.terminationGracePeriodSeconds)
			}
			if _probe.timeoutSeconds != _|_ {
				timeoutSeconds: strconv.Atoi(_probe.timeoutSeconds)
			}
		}

		_sidecarContainerLivenessProbe: {
			_probe: #sidecarContainer.livenessProbe
			if _probe.exec != _|_ {
				exec: command: _probe.exec.command
			}
			if _probe.httpGet != _|_ {
				httpGet: {
					path: _probe.httpGet.path
					if _probe.httpGet.port !~ "^[0-9]+$" {
						port: _probe.httpGet.port
					}
					if _probe.httpGet.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.httpGet.port)
					}
					if _probe.httpGet.host != _|_ {
						host: _probe.httpGet.host
					}
					if _probe.httpGet.httpHeaders != _|_ {
						httpHeaders: _probe.httpGet.httpHeaders
					}
					if _probe.httpGet.scheme != _|_ {
						scheme: _probe.httpGet.scheme
					}
				}
			}
			if _probe.tcpSocket != _|_ {
				tcpSocket: {
					if _probe.tcpSocket.port !~ "^[0-9]+$" {
						port: _probe.tcpSocket.port
					}
					if _probe.tcpSocket.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.tcpSocket.port)
					}
					if _probe.tcpSocket.host != _|_ {
						host: _probe.tcpSocket.host
					}
				}
			}
			if _probe.failureThreshold != _|_ {
				failureThreshold: strconv.Atoi(_probe.failureThreshold)
			}
			if _probe.initialDelaySeconds != _|_ {
				initialDelaySeconds: strconv.Atoi(_probe.initialDelaySeconds)
			}
			if _probe.periodSeconds != _|_ {
				periodSeconds: strconv.Atoi(_probe.periodSeconds)
			}
			if _probe.successThreshold != _|_ {
				successThreshold: strconv.Atoi(_probe.successThreshold)
			}
			if _probe.terminationGracePeriodSeconds != _|_ {
				terminationGracePeriodSeconds: strconv.Atoi(_probe.terminationGracePeriodSeconds)
			}
			if _probe.timeoutSeconds != _|_ {
				timeoutSeconds: strconv.Atoi(_probe.timeoutSeconds)
			}
		}

		_sidecarContainerReadinessProbe: {
			_probe: #sidecarContainer.readinessProbe
			if _probe.exec != _|_ {
				exec: command: _probe.exec.command
			}
			if _probe.httpGet != _|_ {
				httpGet: {
					path: _probe.httpGet.path
					if _probe.httpGet.port !~ "^[0-9]+$" {
						port: _probe.httpGet.port
					}
					if _probe.httpGet.port =~ "^[0-9]+$" {
						if _probe.httpGet.port !~ "^[0-9]+$" {
							port: _probe.httpGet.port
						}
						if _probe.httpGet.port =~ "^[0-9]+$" {
							port: strconv.Atoi(_probe.httpGet.port)
						}
					}
					if _probe.httpGet.host != _|_ {
						host: _probe.httpGet.host
					}
					if _probe.httpGet.httpHeaders != _|_ {
						httpHeaders: _probe.httpGet.httpHeaders
					}
					if _probe.httpGet.scheme != _|_ {
						scheme: _probe.httpGet.scheme
					}
				}
			}
			if _probe.tcpSocket != _|_ {
				tcpSocket: {
					if _probe.tcpSocket.port !~ "^[0-9]+$" {
						port: _probe.tcpSocket.port
					}
					if _probe.tcpSocket.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.tcpSocket.port)
					}
					if _probe.tcpSocket.host != _|_ {
						host: _probe.tcpSocket.host
					}
				}
			}
			if _probe.failureThreshold != _|_ {
				failureThreshold: strconv.Atoi(_probe.failureThreshold)
			}
			if _probe.initialDelaySeconds != _|_ {
				initialDelaySeconds: strconv.Atoi(_probe.initialDelaySeconds)
			}
			if _probe.periodSeconds != _|_ {
				periodSeconds: strconv.Atoi(_probe.periodSeconds)
			}
			if _probe.successThreshold != _|_ {
				successThreshold: strconv.Atoi(_probe.successThreshold)
			}
			if _probe.terminationGracePeriodSeconds != _|_ {
				terminationGracePeriodSeconds: strconv.Atoi(_probe.terminationGracePeriodSeconds)
			}
			if _probe.timeoutSeconds != _|_ {
				timeoutSeconds: strconv.Atoi(_probe.timeoutSeconds)
			}
		}

		_sidecarContainerStartupProbe: {
			_probe: #sidecarContainer.startupProbe
			if _probe.exec != _|_ {
				exec: command: _probe.exec.command
			}
			if _probe.httpGet != _|_ {
				httpGet: {
					path: _probe.httpGet.path
					if _probe.httpGet.port !~ "^[0-9]+$" {
						port: _probe.httpGet.port
					}
					if _probe.httpGet.port =~ "^[0-9]+$" {
						if _probe.httpGet.port !~ "^[0-9]+$" {
							port: _probe.httpGet.port
						}
						if _probe.httpGet.port =~ "^[0-9]+$" {
							port: strconv.Atoi(_probe.httpGet.port)
						}
					}
					if _probe.httpGet.host != _|_ {
						host: _probe.httpGet.host
					}
					if _probe.httpGet.httpHeaders != _|_ {
						httpHeaders: _probe.httpGet.httpHeaders
					}
					if _probe.httpGet.scheme != _|_ {
						scheme: _probe.httpGet.scheme
					}
				}
			}
			if _probe.tcpSocket != _|_ {
				tcpSocket: {
					if _probe.tcpSocket.port !~ "^[0-9]+$" {
						port: _probe.tcpSocket.port
					}
					if _probe.tcpSocket.port =~ "^[0-9]+$" {
						port: strconv.Atoi(_probe.tcpSocket.port)
					}
					if _probe.tcpSocket.host != _|_ {
						host: _probe.tcpSocket.host
					}
				}
			}
			if _probe.failureThreshold != _|_ {
				failureThreshold: strconv.Atoi(_probe.failureThreshold)
			}
			if _probe.initialDelaySeconds != _|_ {
				initialDelaySeconds: strconv.Atoi(_probe.initialDelaySeconds)
			}
			if _probe.periodSeconds != _|_ {
				periodSeconds: strconv.Atoi(_probe.periodSeconds)
			}
			if _probe.successThreshold != _|_ {
				successThreshold: strconv.Atoi(_probe.successThreshold)
			}
			if _probe.terminationGracePeriodSeconds != _|_ {
				terminationGracePeriodSeconds: strconv.Atoi(_probe.terminationGracePeriodSeconds)
			}
			if _probe.timeoutSeconds != _|_ {
				timeoutSeconds: strconv.Atoi(_probe.timeoutSeconds)
			}
		}
	}
}
