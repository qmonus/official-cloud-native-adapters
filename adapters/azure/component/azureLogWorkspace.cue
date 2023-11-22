package azureLogAnalyticsWorkspace

import (
	"qmonus.net/adapter/official/types:azure"

	"strconv"
)

DesignPattern: {
	parameters: {
		appName:                   string
		retentionInDays:           string
		location:                  string
		capacityReservationLevel?: string
		dailyQuotaGb:              string
		workspaceAccessMode:       string
	}

	_azureProvider: provider: "${AzureProvider}"

	_enableLogAccessUsingOnlyResourcePermissions: bool | *true
	if parameters.workspaceAccessMode == "workspace" {
		_enableLogAccessUsingOnlyResourcePermissions: false
	}

	_sku: name: string | *"PerGB2018"
	if parameters.capacityReservationLevel != _|_ {
		_sku: {
			name:                     "CapacityReservation"
			capacityReservationLevel: strconv.Atoi(parameters.capacityReservationLevel)
		}
	}

	resources: app: {
		logAnalyticsWorkspace: azure.#AzureOperationalinsightsWorkspace & {
			options: _azureProvider
			properties: {
				location:          parameters.location
				resourceGroupName: "${resourceGroup.name}"
				sku:               _sku
				workspaceCapping: dailyQuotaGb: strconv.Atoi(parameters.dailyQuotaGb)
				features: {
					if (parameters.retentionInDays == "30") {
						immediatePurgeDataOn30Days: true
					}
					enableLogAccessUsingOnlyResourcePermissions: _enableLogAccessUsingOnlyResourcePermissions
				}
				retentionInDays: strconv.Atoi(parameters.retentionInDays)
				workspaceName:   "qvs-\(parameters.appName)-log-ws"
			}
		}
	}
}
