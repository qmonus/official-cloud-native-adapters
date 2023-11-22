# Deploy Static Site to Azure Static Web Apps Adapter
Qmonus Value Streamを用いて、Azure Static Web AppsにHTML, CSSなどの静的ファイルをデプロイするCloud Native Adapterです。

予め Azure Static Web Apps リソースをデプロイする必要があります。Azure Static Web Appsをデプロイするために[Deploy Static Site to Azure Static Web Apps Adapter](../infrastructure/sample-azureFrontendApplicationAdapterForAzureResources.md)を合わせてご利用いただくか、本AdapterとAzure Frontend Application Adapter for Azure Resourcesを組み合わせた [Azure Frontend Application Adapter](../infrastructure/sample-azureFrontendApplicationAdapter.md) をご利用ください。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/deploy:azureStaticWebApps`

## Level
Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites
* 予めAzure Static Web Appsをデプロイする必要があります。[Azure Frontend Application Adapter for Azure Resources](../infrastructure/sample-azureFrontendApplicationAdapterForAzureResources.md)をご利用ください。

### Constraints
* デプロイするファイルはnpmでパッケージ管理されリポジトリのrootディレクトリでビルドできる必要があります。
* 環境変数を追加する場合はQVS ConfigにenvironmentVariablesパラメータを設定してください。

## Platform
Azure Static Web Apps, Microsoft Azure

## Infrastructure Parameters

| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| environmentVariables | object | no | - | アプリケーションに渡される環境変数名と値のペア | ENV: prod | no |

## ## CI/CD Parameters

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

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| publish-site | git-checkout(-ssh), build-azure-static-web-apps, deploy-azure-static-web-apps のTaskを順番に実行し、静的ファイルをデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | publish-site | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。 |
| git-checkout-ssh | publish-site | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。 |
| generate-environment-variables-file | publish-site | git-checkout or git-checkout-ssh | 環境変数をexportするスクリプトを作成します。|
| build-azure-static-web-apps | publish-site | generate-environment-variables-file | リポジトリ内のnpmプロジェクトをビルドし、静的ファイルを生成します。 |
| deploy-azure-static-web-apps | publish-site | build-azure-static-web-apps | ビルドされた静的ファイルをデプロイします。 |
| get-url-azure-static-web-apps | publish-site | deploy-azure-static-web-apps | デプロイされたアプリケーションの公開URLを取得します。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:azureStaticWebApps
    pipelineParams:
      repositoryKind: github
    params:
      environmentVariables:
        ENV1: $(params.env1)
```

## Code
[deploy:azureStaticWebApps](../../pipeline/deploy/azureStaticWebApps.cue)
