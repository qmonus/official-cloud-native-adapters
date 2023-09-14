# Azure API Backend Application Adapter for Kubernetes Resources

DBとRedisに接続してHTTPSで外部公開できるKubernetesアプリケーションをデプロイするCloud Native Adapterです。

[azureApiBackendApplicationAdapterForAzureResources](./sample-azureApiBackendApplicationAdapterForAzureResources.md) から払い出されるリソースに対応して、以下のKubernetesリソースを作成します。
* Certificate
  * Aレコードとして払い出したドメインを指定し、HTTPS接続を可能にするための証明書を発行します。
* Ingress
  * Certificateリソースと払い出したドメインを指定し、HTTPSアクセスを公開します。
* Service
  * IngressへのアクセスをDeploymentに振り向けます。
* ExternalSecret
  * Key Vaultにアクセスし、アプリケーションがDB接続を行うのに必要なユーザ名とパスワード、およびRedisのパスワードを取得します。
* Deployment
  * パラメータから、DBとRedisのホスト名とポート番号を環境変数としてアプリケーションに渡します。
  * External Secretで生成されたSecretをマウントして、DBユーザ名とそのパスワード、およびRedisのパスワードを環境変数としてアプリケーションに渡します。

## Module

* Module: `qmonus.net/adapter/official`
* Import path `qmonus.net/adapter/official/kubernetes/sample:azureApiBackendApplicationAdapterForKubernetesResources`
* Import path(PulumiYaml形式の場合) `qmonus.net/adapter/official/pulumi/azure/sample:azureApiBackendApplicationAdapterForKubernetesResources`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites

* 以下のCRDをKubernetesクラスタへApplyしてください。
  * External Secrets Operator
  * cert-manager
      * ClusterIssuerリソースも事前に作成してください。
* [azureApiBackendApplicationAdapterForAzureResources](./sample-azureApiBackendApplicationAdapterForAzureResources.md) Adapterを使用してデプロイするリソースとは別に、以下のAzureリソースが事前に必要になります。
  * Azure Cache for Redis
  * Application Gateway
    * AKSのAGICを有効にしてアタッチする
  * 静的IPアドレス
    * Application Gatewayに付与
  * Redisの接続に使用するパスワードを格納したKey Vaultシークレット

### Constraints

* このAdapterでアプリケーションに渡す環境変数は以下のみとなります。
  * アプリケーションが利用するポート番号
  * 接続するデータベースのホスト名
  * データベースに接続するユーザ名
  * データベースに接続するユーザーパスワード
  * Redisのホスト名
  * Redisのポート番号
  * Redisの接続に使用するパスワード
  
## Platform

Kubernetes, Microsoft Azure

## Parameters

| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| appName | string | yes | - | デプロイするアプリケーション名 | myapp | yes |
| k8sNamespace | string | yes | - | アプリケーションをデプロイする対象のNamespace | myapp-namespace | yes |
| portEnvironmentVariableName | string | no | PORT | アプリケーションが利用するポート番号としてアプリケーションPodに渡される環境変数名 | PORT | no |
| port | string | yes | - | アプリケーションが利用するポート番号 | “8080” | no |
| replicas | string | no | "1" | 作成するPodのレプリカ数 | "1" | no |
| imageName | string | yes | - | デプロイするDocker Image | nginx | no |
| dbHostEnvironmentVariableName | string | no | DB_HOST | Azure Database for MySQLのホスト名としてアプリケーションPodに渡される環境変数名 | DB_HOST | no |
| dbHost | string | yes | - | Azure Database for MySQLのホスト名 | myapp.mysql.database.azure.com | no |
| dbUserEnvironmentVariableName | string | no | DB_USER | Azure Database for MySQLに接続するユーザ名としてアプリケーションPodに渡される環境変数名 | DB_USER | no |
| azureKeyVaultDbUserSecretName | string | no | dbuser | Azure Database for MySQLに接続するアカウントのユーザ名が格納されているシークレット名 | dbuser | no |
| dbPasswordEnvironmentVariableName | string | no | DB_PASS | Azure Database for MySQLに接続するユーザのパスワードとしてアプリケーションPodに渡される環境変数名 | DB_PASS | no |
| azureKeyVaultDbPasswordSecretName | string | no | dbpassword | Azure Database for MySQLに接続するユーザのパスワードが格納されているシークレット名 | dbpassword | no |
| redisHostEnvironmentVariableName | string | no | REDIS_HOST | Azure Cache for Redisのホスト名としてアプリケーションPodに渡される環境変数名 | REDIS_HOST | no |
| redisHost | string | yes | - | Azure Cache for Redisのホスト名 | myapp.redis.cache.windows.net | no |
| redisPortEnvironmentVariableName | string | no | REDIS_PORT | Azure Cache for Redisのポート番号としてアプリケーションPodに渡される環境変数名 | REDIS_PORT | no |
| redisPort | string | no | "6380" | Azure Cache for Redisのポート番号（6380 または 6379 のみ指定可能） | "6380" | no |
| redisPasswordEnvironmentVariableName | string | no | REDIS_PASS | Azure Cache for Redisの接続に使用するパスワードとしてアプリケーションPodに渡される環境変数名 | REDIS_PASS | no |
| redisPasswordSecretName | string | yes | - | Azure Cache for Redisの接続に使用するパスワードが格納されているシークレット名 | myapp-redis-pass-secret | no |
| hostEnvironmentVariableName | string | no | HOST | 公開するアプリケーションのホスト名としてアプリケーションPodに渡される環境変数名 | HOST | no |
| host | string | yes | - | 公開するアプリケーションのホスト名 | www.myapp.example.com | no |
| clusterIssuerName | string | yes | - | 使用するClusterIssuerリソース名 | myapp-cluster-issuer | no |
| clusterSecretStoreName | string | no | qvs-global-azure-store | 使用するClusterSecretStoreリソース名 | qvs-global-azure-store | no |
| k8sProvider | string | no | k8sProvider | Pulumi yamlで使用するKubernetes Provider名(PulumiYaml形式の場合のみ指定可能) | k8sProvider | no |

## Resources
| Resource ID | Provider | API version | Kind | Description |
| --- | --- | --- | --- | --- |
| ingress | kubernetes | v1 | Ingress | Serviceに対する外部からのアクセスを管理します |
| service | kubernetes | v1 | Service | 各Node上で、静的なポートでServiceを公開します |
| deployment | kubernetes | apps/v1 | Deployment | デプロイするPodリソース（アプリケーション）を定義します |
| certificate | kubernetes | cert-manager.io/v1  | Certificate | アプリケーションを公開するために使用するTLS証明書を定義します |
| externalSecret | kubernetes | external-secrets.io/v1beta1 | ExternalSecret | 外部プロバイダの機密情報をSecretリソースとして使用できるようにします |

## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/kubernetes:azureApiBackendApplicationAdapterForKubernetesResources
    params:
      appName: $(params.appName)
      k8sNamespace: $(params.k8sNamespace)
      port: $(params.port)
      imageName: $(params.imageName)
      dbHost: $(params.dbHost)
      azureKeyVaultDbUserSecretName: $(params.azureKeyVaultDbUserSecretName)
      azureKeyVaultDbPasswordSecretName: $(params.azureKeyVaultDbPasswordSecretName)
      redisHost: $(params.redisHost)
      redisPort: $(params.redisPort)
      redisPasswordSecretName: $(params.redisPasswordSecretName)
      host: $(params.host)
      clusterIssuerName: $(params.clusterIssuerName)
      clusterSecretStoreName: $(params.clusterSecretStoreName)
```

## Code

[azureApiBackendApplicationAdapterForKubernetesResources](../../kubernetes/sample/azureApiBackendApplicationAdapterForKubernetesResources.cue)

[azureApiBackendApplicationAdapterForKubernetesResources](../../pulumi/azure/sample/azureApiBackendApplicationAdapterForKubernetesResources.cue)(PulumiYaml形式の場合)
