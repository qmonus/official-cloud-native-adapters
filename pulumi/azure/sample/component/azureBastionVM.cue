package azureBastionVM

import (
	"qmonus.net/adapter/official/pulumi/base/azure"
	"qmonus.net/adapter/official/pulumi/base/tls"
)

DesignPattern: {
	name: "sample:azureBastionVM"

	parameters: {
		appName:       string
		bastionVmSize: string | *"Standard_DS1_v2"
	}

	_azureProvider: provider: "${AzureProvider}"
	_tlsProvider: provider:   "${TlsProvider}"

	resources: app: {
		bastionSshKey: tls.#Resource & {
			type:    "tls:PrivateKey"
			options: _tlsProvider
			properties: {
				algorithm: "RSA"
			}
		}

		bastionSshKeySecret: azure.#Resource & {
			type: "azure-native:keyvault:Secret"
			options: {
				dependsOn: ["${keyVaultAccessPolicyForQvs}"]
				_azureProvider
			}
			properties: {
				properties: {
					value: "${bastionSshKey.privateKeyOpenssh}"
				}
				resourceGroupName: "${resourceGroup.name}"
				secretName:        "bastionsshkey"
				vaultName:         "${keyVault.name}"
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		bastionNIC: azure.#Resource & {
			type:    "azure-native:network:NetworkInterface"
			options: _azureProvider
			properties: {
				networkInterfaceName: "qvs-\(parameters.appName)-bastion-nic"
				resourceGroupName:    "${resourceGroup.name}"
				nicType:              "Standard"
				location:             "japaneast"
				ipConfigurations: [
					{
						name:                      "qvs-\(parameters.appName)-bastion-nic-ipconfig"
						primary:                   true
						privateIPAllocationMethod: "Dynamic"
						subnet: id:          "${virtualNetworkBastionSubnet.id}"
						publicIPAddress: id: "${bastionPublicIpAddress.id}"
					},
				]
				tags: "managed-by": "Qmonus Value Stream"
			}
		}

		bastionVM: azure.#Resource & {
			type: "azure-native:compute:VirtualMachine"
			options: {
				dependsOn: ["${bastionNIC}", "${bastionSshKey}"]
				_azureProvider
			}
			properties: {
				vmName:            "qvs-\(parameters.appName)-bastion-vm"
				resourceGroupName: "${resourceGroup.name}"
				hardwareProfile: vmSize: "\(parameters.bastionVmSize)"
				location: "japaneast"
				networkProfile: {
					networkInterfaces: [{
						id: "${bastionNIC.id}"
					}]
				}
				osProfile: {
					adminUsername: "azureuser"
					computerName:  "qvs-\(parameters.appName)-bastion"
					linuxConfiguration: {
						disablePasswordAuthentication: true
						ssh: {
							publicKeys: [{
								keyData: "${bastionSshKey.publicKeyOpenssh}"
								path:    "/home/azureuser/.ssh/authorized_keys"
							}]
						}
					}
				}
				storageProfile: {
					imageReference: {
						offer:     "0001-com-ubuntu-server-focal"
						publisher: "canonical"
						sku:       "20_04-lts-gen2"
						version:   "latest"
					}
					osDisk: {
						createOption: "FromImage"
						diskSizeGB:   30
						name:         "qvs-\(parameters.appName)-bastion-vm-os-disk"
						osType:       "Linux"
						deleteOption: "delete"
					}
				}
				zones: ["1"]
				tags: "managed-by": "Qmonus Value Stream"
			}
		}
	}
}
