# Azure API Backend Application Adapter for Azure Resources

HTTPSで外部公開できるアプリケーションをデプロイするために、関連するAzureリソースをデプロイするCloud Native Adapterです。

以下のリソースを作成します。

* Azure DNS
  * レコードセット (Aレコード)
* Azure Database for MySQL
  * データベース
  * 作成したデータベースへのGLANT ALL権限をもつユーザーアカウント
* Azure Key Valut
  * MySQLのユーザー名、パスワードを格納したシークレット

## Module

* Module: `qmonus.net/adapter/official`
* Import path `qmonus.net/adapter/official/pulumi/azure/sample:azureApiBackendApplicationAdapterForAzureResources`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites

* 事前に以下のリソースを作成してください。
  * Azure DNS
    * ゾーン
  * Azure Database for MySQL
    * サーバー
  * Azure Key Valut
    * キーコンテナ
      * デプロイ時に使用するService Principalのアクセスをキーコンテナのアクセスポリシーで許可してください。
* 以下のProvider AdapterもQVS Configに指定してください。
  * `qmonus.net/adapter/official/pulumi/provider:azure`
  * `qmonus.net/adapter/official/pulumi/provider:mysql`

### Constraints

* 作成するMySQLのユーザアカウントのパスワードは固定値となっています。

## Platform

Microsoft Azure

## Parameters

| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| appName | string | yes | - | デプロイするアプリケーション名 |
| azureProvider | string | no | AzureProvider | Pulumi yamlで使用するAzure Provider名 |
| mysqlProvider | string | no | MysqlProvider | Pulumi yamlで使用するMySQL Provider名 |
| azureResourceGroupName | string | yes | - | 事前に用意したAzureのリソースが含まれるリソースグループ名 |
| azureDnsZoneName | string | yes | - | 事前に用意したDNSゾーン名 |
| azureDnsARecordName | string | yes | - | 新たに作成するAレコード名 |
| azureStaticIpAddress | string | yes | - | 新たに作成するAレコードで指定するIPアドレス |
| azureARecordTtl | string | no | "3600" |  新たに作成するAレコードに設定するTTLの値 |
| mysqlCreateUserName | string | no | dbuser | 新たに作成するMySQLのユーザー名 |
| mysqlCreateDbName | string | yes | - | 新たに作成するMySQLのデータベース名 |
| mysqlCreateDbCharacterSet | string | no | utf8mb3 | 新たに作成するMySQLのデータベースに設定するキャラクタセット |
| azureKeyVaultKeyContainerName| string | yes | - | 事前に用意したキーコンテナ名 |
| azureKeyVaultDbUserSecretName | string | no | dbuser | MySQLのユーザー名を格納するシークレット名 |
| azureKeyVaultDbPasswordSecretName  | string | no | dbpassword | MySQLのユーザーパスワードを格納するシークレット名 |

## Resources
| Resources Name | Provider | PaaS | Description |
| --- | --- | --- | --- |
| aRecord | Azure | Azure DNS | レコードセットに新たにAレコードを追加します。 |
| database | Azure | Azure Database for MySQL | MySQLサーバーに新たにデータベースを作成します。 |
| user | Azure | Azure Database for MySQL | MySQLサーバーに新たにユーザーを作成します。 |
| grant | Azure | Azure Database for MySQL | ユーザーに作成したデータベースへの権限を付与します。 |
| dbUserSecret | Azure | Azure Key Valut | 新規作成したMySQLユーザー名を格納したシークレットを作成します。 |
| dbPasswordSecret | Azure | Azure Key Valut | 新規作成したMySQLユーザーパスワードを格納したシークレットを作成します。 |

## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pulumi/provider:azure
  - pattern: qmonus.net/adapter/official/pulumi/provider:mysql
  - pattern: qmonus.net/adapter/official/azure/sample:azureApiBackendApplicationAdapterForAzureResources
    params:
      appName: $(params.appName)
      azureResourceGroupName: $(params.azureResourceGroupName)
      azureDnsZoneName: $(params.azureDnsZoneName)
      azureDnsARecordName: $(params.azureDnsARecordName)
      azureStaticIpName: $(params.azureStaticIpName)
      azureARecordTtl: $(params.azureARecordTtl)
      mysqlCreateDbName:  $(params.mysqlCreateDbName)
      azureKeyVaultKeyContainerName: $(params.azureKeyVaultKeyContainerName)
```

## Code

[azureApiBackendApplicationAdapterForAzureResources](../../pulumi/azure/sample/azureApiBackendApplicationAdapterForAzureResources.cue)