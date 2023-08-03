# Azure Frontend Application Adapter

以下のCloud Native Adapterを組み合わせて、静的WebアプリケーションをデプロイするCloud Native Adapterです。各Cloud Native Adapterのドキュメントも合わせてご覧ください。

* [Deploy Static Site to Azure Static Web Apps Adapter](../cicd/deploy-staticSiteToAzureStaticWebApps.md)
* [Azure Frontend Application Adapter for Azure Resources](sample-azureFrontendApplicationAdapterForAzureResources.md)

以下のリソースと静的ファイルをデプロイするPipeline Manifestを作成します。

* Azure Static Web Apps
  * Webアプリケーションを外部公開するサービス
* Azure DNS
  * レコードセット (CNAMEレコード)

![Architecture](images/azureFrontendApplication.png)

## Module

* Module: `qmonus.net/adapter/official`
* Import path: `qmonus.net/adapter/official/pulumi/azure/sample:azureFrontendApplicationAdapter`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites
* 事前に以下のリソースを作成してください。
    * Azure DNS
        * ゾーン

* 以下のProvider AdapterをQVS Configに指定してください。
    * `qmonus.net/adapter/official/pulumi/provider:azure`

### Constraints
* デプロイするファイルはnpmでパッケージ管理されリポジトリのrootディレクトリでビルドできる必要があります。

## Platform

Azure Static Web Apps, Microsoft Azure

## Infrastructure Parameters

| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| appName | string | yes | - | デプロイするアプリケーション名 |
| azureProvider | string | no | AzureProvider | Pulumi yamlで使用するAzure Provider名 |
| azureSubscriptionId | string | yes | - | 事前に用意したAzureのリソースが含まれるサブスクリプション名 |
| azureResourceGroupName | string | yes | - | 事前に用意したAzureのリソースが含まれるリソースグループ名 |
| azureStaticSiteLocation | string | yes | - | Static Web Appsをデプロイするロケーション |
| azureStaticSiteName | string | yes | - | デプロイするStatic Web Appsのリソース名 |
| azureDnsZoneName | string | yes | - | 事前に用意したDNSゾーン名 |
| azureCnameRecordTtl | string | no | "3600" | 新たに作成するCレコードに設定するTTLの値 |

## CI/CD Parameters
### Adapter Options
| Parameter Name | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| repositoryKind | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab |
| useSshKey | bool | no | false | trueを指定するとリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。 | true |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision | string | yes | - | Gitのリビジョン | | no |
| gitRepositoryDeleteExisting | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているSecret名 | | yes |
| azureApplicationId | string | yes | - | AzureのApplicationID | | yes |
| azureTenantId | string | yes | - | AzureのTenantID | | yes |
| azureSubscriptionId | string | yes | - | AzureのSubscriptionID | | yes |
| azureClientSecretName | string | yes | - | AzureのClientSecretを保管しているSecret名 | | yes |
| azureStaticSiteName | string | yes | - | デプロイするStatic Web Appsのリソース名 | myStaticSite | no |

## Application Resources
| Resource ID | Provider | PaaS | Description |
| --- | --- | --- | --- |
| staticSite | Azure | Azure Static Web Apps | Webアプリケーションをデプロイします |
| cnameRecord | Azure | Azure DNS | レコードセットに新たにCNAMEレコードを追加します |
| staticSiteCustomDomain | Azure | Azure Static Web Apps | 作成したCNAMEレコードを利用してWebアプリケーションにカスタムドメインを設定します |

## Pipeline Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| deploy-static-site | git-checkout(-ssh), build-azure-static-web-apps, deploy-azure-static-web-apps のTaskを順番に実行し、静的ファイルをデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | deploy-static-site | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。 |
| git-checkout-ssh | deploy-static-site | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。 |
| build-azure-static-web-apps | deploy-static-site | git-checkout or git-checkout-ssh | リポジトリ内のnpmプロジェクトをビルドし、静的ファイルを生成します。 |
| deploy-azure-static-web-apps | deploy-static-site | build-azure-static-web-apps | ビルドされた静的ファイルをデプロイします。 |

## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pulumi/provider:azure
  - pattern: qmonus.net/adapter/official/pulumi/azure/sample:azureFrontendApplicationAdapter
    params:
      appName: $(params.appName)
      azureStaticSiteLocation: $(params.azureStaticSiteLocation)
      azureStaticSiteName: $(params.azureStaticSiteName)
      azureSubscriptionId: $(params.azureSubscriptionId)
      azureResourceGroupName: $(params.azureResourceGroupName)
      azureDnsZoneName: $(params.azureDnsZoneName)
```

## Code

[azureFrontendApplicationAdapter](../../pulumi/azure/sample/azureFrontendApplicationAdapter.cue)
