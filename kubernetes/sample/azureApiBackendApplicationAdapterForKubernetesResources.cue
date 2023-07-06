package azureApiBackendApplicationAdapterForKubernetesResources

import (
	"strconv"

	"qmonus.net/adapter/official/kubernetes:types"
)

DesignPattern: {
	name: "kubernetes:azureApiBackendApplicationAdapterForKubernetesResources"

	parameters: {
		appName:                              string
		clusterIssuerName:                    string
		k8sNamespace:                         string
		imageName:                            string
		replicas:                             string | *"1"
		portEnvironmentVariableName:          string | *"PORT"
		port:                                 string
		dbHostEnvironmentVariableName:        string | *"DB_HOST"
		dbHost:                               string
		dbUserEnvironmentVariableName:        string | *"DB_USER"
		azureKeyVaultDbUserSecretName:        string | *"dbuser"
		dbPasswordEnvironmentVariableName:    string | *"DB_PASS"
		azureKeyVaultDbPasswordSecretName:    string | *"dbpassword"
		redisHostEnvironmentVariableName:     string | *"REDIS_HOST"
		redisHost:                            string
		redisPortEnvironmentVariableName:     string | *"REDIS_PORT"
		redisPort:                            string | *"6379"
		redisPasswordEnvironmentVariableName: string | *"REDIS_PASS"
		redisPasswordSecretName:              string
		host:                                 string
		secretStoreName:                      string | *"azure-key-vault"
	}

	resources: app: {
		ingress: types.#Ingress & {
			metadata: {
				name:      parameters.appName
				namespace: parameters.k8sNamespace
				annotations: {
					"kubernetes.io/ingress.class":    "azure/application-gateway"
					"cert-manager.io/cluster-issuer": parameters.clusterIssuerName
				}
			}
			spec: {
				rules: [
					{
						host: parameters.host
						http: {
							paths: [{
								path:     "/*"
								pathType: "ImplementationSpecific"
								backend: {
									service: {
										name: parameters.appName
										port: {
											number: 80
										}
									}
								}
							}]
						}
					},
				]
				tls: [
					{
						hosts: [parameters.host]
						secretName: "\(parameters.appName)-certificate-secret"
					},
				]
			}
		}

		service: types.#Service & {
			metadata: {
				name:      parameters.appName
				namespace: parameters.k8sNamespace
			}
			spec: {
				type: "NodePort"
				ports: [{
					port:       80
					targetPort: strconv.Atoi(parameters.port)
				}]
				selector: {
					app: parameters.appName
				}
			}
		}

		deployment: types.#Deployment & {
			metadata: {
				name:      parameters.appName
				namespace: parameters.k8sNamespace
				annotations: "vs.axis-dev.io/dependsOn": "external-secrets.io:ExternalSecret::\(parameters.k8sNamespace)/\(parameters.appName)"
			}
			spec: {
				minReadySeconds: int | *60
				replicas:        strconv.Atoi(parameters.replicas)
				selector: matchLabels: {
					app: parameters.appName
				}
				template: {
					metadata: labels: {
						app: parameters.appName
					}
					spec: {
						terminationGracePeriodSeconds: int | *60
						containers: [
							{
								name:  parameters.appName
								image: parameters.imageName
								env: [{
									name:  parameters.portEnvironmentVariableName
									value: parameters.port
								}, {
									name:  parameters.dbHostEnvironmentVariableName
									value: parameters.dbHost
								}, {
									name: parameters.dbUserEnvironmentVariableName
									valueFrom: secretKeyRef: {
										name: "\(parameters.appName)-application-secret"
										key:  parameters.azureKeyVaultDbUserSecretName
									}
								}, {
									name: parameters.dbPasswordEnvironmentVariableName
									valueFrom: secretKeyRef: {
										name: "\(parameters.appName)-application-secret"
										key:  parameters.azureKeyVaultDbPasswordSecretName
									}
								}, {
									name:  parameters.redisHostEnvironmentVariableName
									value: parameters.redisHost
								}, {
									name:  parameters.redisPortEnvironmentVariableName
									value: parameters.redisPort
								}, {
									name: parameters.redisPasswordEnvironmentVariableName
									valueFrom: secretKeyRef: {
										name: "\(parameters.appName)-application-secret"
										key:  parameters.redisPasswordSecretName
									}
								}]
								ports: [{
									containerPort: strconv.Atoi(parameters.port)
								}, ...]
							},
						]
					}
				}
			}
		}

		certificate: types.#Certificate & {
			metadata: {
				name:      parameters.appName
				namespace: parameters.k8sNamespace
			}
			spec: {
				dnsNames: [parameters.host]
				issuerRef: {
					group: "cert-manager.io"
					kind:  "ClusterIssuer"
					name:  parameters.clusterIssuerName
				}
				secretName: "\(parameters.appName)-certificate-secret"
				privateKey: rotationPolicy: "Always"
			}
		}

		externalSecret: types.#ExternalSecret & {
			metadata: {
				name:      parameters.appName
				namespace: parameters.k8sNamespace
			}
			spec: {
				refreshInterval: "0"
				secretStoreRef: {
					name: parameters.secretStoreName
					kind: "ClusterSecretStore"
				}
				target: {
					name:           "\(parameters.appName)-application-secret"
					creationPolicy: "Owner"
				}
				data: [{
					secretKey: parameters.azureKeyVaultDbUserSecretName
					remoteRef: {
						key: parameters.azureKeyVaultDbUserSecretName
					}
				}, {
					secretKey: parameters.azureKeyVaultDbPasswordSecretName
					remoteRef: {
						key: parameters.azureKeyVaultDbPasswordSecretName
					}
				}, {
					secretKey: parameters.redisPasswordSecretName
					remoteRef: {
						key: parameters.redisPasswordSecretName
					}
				}]
			}
		}
	}
}
