# Azure App Service Adapter

HTTPSで外部公開できるアプリケーションを Azure App Service 上にデプロイするCloud Native Adapterです。

以下のリソースを作成します。

* Azure DNS
    * レコードセット (CNAME レコード)
    * レコードセット (TXT レコード)
* Azure App Service Plan
* Azure App Service
    * Web Apps for Containers
    * App Service Managed Certificate
        * CNAMEレコードとして払い出したドメインを指定し、HTTPS接続を可能にするための証明書を発行します。

<img src="images/azureAppServiceAdapter-architecture.png" class="img_zoom">

## Module

* Module: `qmonus.net/adapter/official`
* Import path: `qmonus.net/adapter/official/pulumi/azure/sample:azureAppService`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites

* 事前に以下のリソースを作成してください。
    * Azure DNS Zone
    * Azure Container Registry
    * Azure Cache for Redis
    * Azure Database for MySQL
    * Azure Key Vault
        * MySQL, Redisの接続に使用するパスワードを格納したKey Vaultシークレット

### Constraints

このAdapterでアプリケーションに渡す環境変数は以下になります。

| Environment Variable            | Description                          |
|---------------------------------|--------------------------------------|
| DB_HOST                         | 接続するデータベースのホスト名                      |
| DB_USER                         | データベースに接続するユーザ名                      |
| DB_PASS                         | データベースに接続するユーザーパスワード                 |
| REDIS_HOST                      | Redisのホスト名                           |
| REDIS_PASS                      | Redisの接続に使用するパスワード                   |
| REDIS_PORT                      | Redisのポート番号                          |
| DOCKER_REGISTRY_SERVER_URL      | Azure Container RegistryのサーバーURL     |
| DOCKER_REGISTRY_SERVER_USERNAME | Azure Container RegistryのAdmin ユーザー名 |
| DOCKER_REGISTRY_SERVER_PASSWORD | Azure Container RegistryのAdmin パスワード |

## Platform

App Service, Microsoft Azure

## Infrastructure Parameters

| Parameter Name         | Type   | Required | Default | Description                                         | Example                                                                                                                                                     | Auto Binding |
|------------------------|--------|----------|---------|-----------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|
| appName                | string | yes      | -       | デプロイするアプリケーション名                                     | sample                                                                                                                                                      | yes          |
| azureSubscriptionId    | string | yes      | -       | 事前に用意したAzureのリソースが含まれるサブスクリプション名                    | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx                                                                                                                        | yes          |
| azureResourceGroupName | string | yes      | -       | 事前に用意したAzureのリソースが含まれるリソースグループ名                     | sample-rg                                                                                                                                                   | yes          |
| azureKeyVaultName      | string | yes      | -       | 事前に用意したAzure Key Vault名                             | SampleKeyVault                                                                                                                                              | no           |
| containerRegistryName  | string | yes      | -       | 事前に用意したContainer Registry名                          | SampleRegistry                                                                                                                                              | no           |
| subnetId               | string | no       | ""      | Web Appsのデプロイ先のSubnet ID (指定しない場合はSubnet外にデプロイされます) | /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /resourceGroups/sample-rg/providers/Microsoft.Network/virtualNetworks/sample-vnet/sample-web-app-subnet | no           |
| azureDnsZoneName       | string | yes      | -       | 事前に用意したDNSゾーン名                                      | example.com                                                                                                                                                 | no           |
| subDomainName          | string | no       | api     | アプリケーションに紐づけるサブドメイン名                                | api                                                                                                                                                         | no           |
| dbHost                 | string | yes      | -       | Azure Database for MySQLのホスト名                       | sample-db.mysql.database.azure.com                                                                                                                          | no           |
| redisHost              | string | yes      | -       | Azure Cache for Redisのホスト名                          | sample-redis.redis.cache.windows.net                                                                                                                        | no           |
| imageFullNameTag       | string | yes      | -       | イメージ名のフルパスにタグ名を加えたもの                                | sample-registry.azurecr.io/sample-app:latest                                                                                                                | yes          |

## CI/CD Parameters

### Adapter Options

| Parameter Name | Type   | Required | Default | Description                                                                                                      | Example |
|----------------|--------|----------|---------|------------------------------------------------------------------------------------------------------------------|---------|
| repositoryKind | string | no       | ""      | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab  |
| useSshKey      | bool   | no       | false   | trueを指定するとリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。                                                               | true    |

### Parameters

| Parameter Name              | Type   | Required | Default    | Description                                        | Example                                              | Auto Binding |
|-----------------------------|--------|----------|------------|----------------------------------------------------|------------------------------------------------------|--------------|
| gitCloneUrl                 | string | yes      | -          | GitリポジトリサービスのURL                                   | https://github.com/${organization}/<br>${repository} | yes          |
| gitRevision                 | string | yes      | -          | Gitのリビジョン                                          |                                                      | no           |
| gitRepositoryDeleteExisting | bool   | no       | true       | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する   |                                                      | no           |
| gitCheckoutSubDirectory     | string | no       | ""         | GitのCheckout作業をするパス名                               |                                                      | no           |
| gitTokenSecretName          | string | yes      | -          | Gitのアクセストークンを保管しているk8s Secret名                     |                                                      | yes          |
| gitSshKeySecretName         | string | yes      | -          | GitのSSH Keyを保管しているk8s Secret名                      |                                                      | yes          |
| azureApplicationId          | string | yes      | -          | AzureのApplicationID                                |                                                      | yes          |
| azureClientSecretName       | string | yes      | -          | AzureのClientSecretを保管しているSecret名                   |                                                      | yes          |
| dockerfile                  | string | yes      | Dockerfile | ビルドするdockerfileのファイル名                              |                                                      | no           |
| imageRegistryPath           | string | no       | -          | ビルドしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス             | ${acr_name}.azurecr.io/sample                        | no           |
| imageShortName              | string | yes      | -          | ビルドするコンテナイメージの省略名。ACRのリポジトリ名を指定する。                 | nginx                                                | no           |
| imageTag                    | string | yes      | -          | コンテナイメージのタグ名。buildcacheというタグ名は予約されているため指定できません。                                       | v1.0.0                                               | no           |
| pathToContext               | string | yes      | .          | ソースディレクトリからの相対パス                                   |                                                      | no           |
| extraArgs                   | string | yes      | ""         | Buildkitでイメージをビルドする際に追加で設定するオプション                  |                                                      | no           |
| pathToSource                | string | no       | ""         | ソースディレクトリからの相対パス                                   |                                                      | no           |
| qvsConfigPath               | string | yes      | -          | QVS Config(旧称：Application Config)のパス               | .valuestream/qvs.yaml                                | yes          |
| appName                     | string | yes      | -          | QVSにおけるApplication名                                | nginx                                                | yes          |
| qvsDeploymentName           | string | yes      | -          | QVSにおけるDeployment名                                 | staging                                              | yes          |
| deployStateName             | string | no       | app        | pulumi-stack名のSuffixとして使用される                       |                                                      | no           |
| kubeconfigSecretName        | string | no       | -          | QVSにおけるDeploymentの作成時に指定したkubeconfigを保管しているSecret名 |                                                      | yes          |
| azureTenantId               | string | no       | -          | AzureのTenantID                                     |                                                      | yes          |
| azureSubscriptionId         | string | no       | -          | AzureのSubscriptionID                               |                                                      | yes          |

## Application Resources

| Resource ID           | Provider | PaaS              | API version | Kind | Description                                            |
|-----------------------|----------|-------------------|-------------|------|--------------------------------------------------------|
| cnameRecord           | Azure    | Azure DNS         |             |      | レコードセットに新たにCNAMEレコードを追加します。                            |
| txtRecord             | Azure    | Azure DNS         |             |      | レコードセットに新たにTXTレコードを追加します。（カスタムドメインの紐付けの際の検証に使用します）     |
| appServicePlan        | Azure    | Azure App Service |             |      | Web App Service をホスティングするための  App Service Plan を作成します。 |
| webAppForContainer    | Azure    | Azure App Service |             |      | コンテナ化されたアプリケーションをデプロイするための Web App Service を作成します。     |
| webAppHostNameBinding | Azure    | Azure App Service |             |      | デプロイした Web App Service にカスタムドメインをバインドします。              |
| managedCertificate    | Azure    | Azure App Service |             |      | 無料の App Service マネージド証明書を作成します。                        |
| certBinding           | Azure    | Azure App Service |             |      | カスタムドメインに マネージド証明書をバインドします。                            |

## Pipeline Resources

以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline

| Resource ID | Description                                                                                                            |
|-------------|------------------------------------------------------------------------------------------------------------------------|
| build       | git-checkout(-ssh), docker-login-azure, buildkit のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。                          |
| deploy      | git-checkout(-ssh), compile-adapter-into-pulumi-yaml(-ssh), deploy-by-pulumi-yaml のTaskを順番に実行し、アプリケーションを指定の環境にデプロイします。 |

### Task

| Resource ID                          | Pipeline      | runAfter                                                                 | Description                                                                                                                                                       |
|--------------------------------------|---------------|--------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| git-checkout                         | build, deploy | -                                                                        | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。                   |
| git-checkout-ssh                     | build, deploy | -                                                                        | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。                 |
| docker-login-azure                   | build         | git-checkout or git-checkout-ssh                                         | 指定したAzure Container Registryへの認証を行います。                                                                                                                            |
| buildkit                             | build         | docker-login-azure                                                       | Dockerfileからイメージをビルドし、コンテナレジストリへプッシュします。                                                                                                                          |
| compile-adapter-into-pulumi-yaml     | deploy        | git-checkout                                                             | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、PulumiYamlのプロジェクトファイルを生成します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。     |
| compile-adapter-into-pulumi-yaml-ssh | deploy        | git-checkout-ssh                                                         | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、PulumiYamlのプロジェクトファイルを生成します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。 |
| deploy-by-pulumi-yaml                | deploy        | compile-adapter-into-pulumi-yaml or compile-adapter-into-pulumi-yaml-ssh | コンパイルされたPulumiYamlのプロジェクトファイルを指定の環境にデプロイします。                                                                                                                      |

## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pulumi/azure/sample:azureAppService
    params:
      appName: $(params.appName)
      azureSubscriptionId: $(params.azureSubscriptionId)
      azureResourceGroupName: $(params.azureResourceGroupName)
      containerRegistryName: $(params.containerRegistryName)
      dnsZoneName: $(params.dnsZoneName)
      subnetId: $(params.subnetId)
      subDomainName: $(params.subDomainName)
      dbHost: $(params.dbHost)
      redisHost: $(params.redisHost)
      azureKeyVaultName: $(params.azureKeyVaultName)
      imageFullNameTag: $(params.imageFullNameTag)
```

## Code

[azureAppServiceAdapter](../../pulumi/azure/sample/azureAppService.cue)
