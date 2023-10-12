# How to use Frontend Adapter

[Frontend Adapter](../../../../../adapters/azure/serverless/staticSite/frontend/README.md) は、 [Shared Infrastructure Adapter](../../../../../adapters/azure/serverless/staticSite/frontend/sharedInfrastructure/README.md) によってデプロイされた共有リソースと組み合わせて利用することで、Azure Static Web Apps を利用して静的Webアプリケーションを迅速にデプロイすることができます。
このドキュメントではお手持ちのアプリケーションを利用して、Azure 上に静的 Web アプリケーションをデプロイする方法を記載しています。

## 事前準備

Adapter を利用して静的 Web アプリケーションをデプロイするにあたり、以下の項目をご準備ください。

1. サービスプリンシパルの作成  
    Frontend Adapter を利用してWebアプリケーションをデプロイする際、Azure Static Web Apps を利用するための Service Principal を作成する必要があります。
    [ポータルで Azure AD アプリとサービス プリンシパルを作成する](https://learn.microsoft.com/ja-jp/azure/active-directory/develop/howto-create-service-principal-portal) と、[Frontend Adapter](../../../../../adapters/azure/serverless/staticSite/frontend/README.md) を参考にして、必要な権限を付与したサービスプリンシパルを作成してください

2. 共有リソースの作成  
    Frontend Adapter を利用する際には、事前に [Shared Infrastructure Adapter](../../../../../adapters/azure/serverless/staticSite/frontend/sharedInfrastructure/README.md)によってリソースがデプロイされている必要があります。

## 手順

### 1. QVS Configをリポジトリに登録

公開するアプリケーションのリポジトリに[QVS Config](./qvs.yaml)を追加します。

```bash
# ブランチを作成
$ git checkout -b frontend-sample

# .valuestream フォルダ直下にQVS Config を作成
$ mkdir .valuestream
$ vi .valuestream/qvs.yaml

# push
$ git add .valuestream/qvs.yaml
$ git commit -m 'frontend adapter sample'
$ git push origin frontend-sample
```

### 2. Application作成

以下の値でApplicationを作成します。

- Display Name: frontend-sample
- Description: (任意の文章または空白)
- QVS Config Repository: + Create New Repository でRepositoryを作成
    - Repository Kind: (持ちこむリポジトリに合わせて選択)
    - Git Clone Protocol: (持ちこむリポジトリの認証形式に合わせて選択)
    - Repository Visibility: (持ちこむリポジトリに合わせて選択)
    - Git Clone URL: (持ちこむリポジトリに合わせて設定)
    - Description: (任意の文章または空白)
- QVS Config File Path: .valuestream/qvs.yaml

### 3. Deployment作成

以下の値でDeploymentを作成します。

- Environment: + Create New Environment でEnvironmentを作成
    - Display Name: frontend-sample
    - Description: (任意の文章または空白)
    - Provisioning Target:
        - Kind: azure
        - Tenant ID: (テナントID)
        - Subscription ID: (サブスクリプションID)
        - Resource Group Name:(リソースグループ名)
        - Application ID: (リソースグループ名)
        - publicにチェック
- Display Name: frontend-sample
- Name: (Environment選択時に自動入力)
- Credentials
    - Service Principal: (サービスプリンシパルのクライアントシークレット)

### 4. Pipeline / Task 作成

以下の値でCOMPILE & APPLY PIPELINE/TASKを実行します。

- Application: frontend sample
- Git Rivision: frontend-sample

### 5. AssemblyLine 作成

以下のAssemblyLineをImportしてください。

```yaml
apiVersion: vs.axis-dev.io/v1
kind: AssemblyLine
metadata:
  name: frontend-sample
spec:
  params:
    - name: gitRevision
      description: ""
  results:
    - name: publicUrl
      value: $(stages.publish-site.results.publicUrl)
    - name: gitRevision
      value: $(inputs.gitRevision)
  stages:
    - name: deploy
      spec:
        deployment:
          app: frontend-sample
          name: frontend-sample
        params:
          - name: gitRevision
            value: $(inputs.gitRevision)
        pipeline: frontend-sample-deploy
    - name: publish-site
      spec:
        deployment:
          app: frontend-sample
          name: frontend-sample
        params:
          - name: gitRevision
            value: $(inputs.gitRevision)
        pipeline: frontend-sample-publish-site
      runAfter:
        - deploy

```

### 6. Deployment Config

Deployment Configに、共有リソースによってデプロイされたDNSゾーンを設定してください。

```yaml
azureDnsZoneName: <DNSゾーン名>
```

### 7. AssemblyLine 実行

Input ParametersのgitRivisionに公開したいアプリケーションのリポジトリのブランチ名(`frontend-sample`)もしくは最新のコミットIDを指定して、実行してください。

※ ブランチ名を入力する場合、最新のコミットIDを利用して実行することができます。

### 8. 確認

AssemblyLineの実行が完了した後、AssemblyLine Resultsに表示される公開用URLにアクセスできることを確認します。

## ユースケースに応じた設定変更

デプロイするアプリケーションを公開する際に利用できる Optional なパラメータが2つあります。ユースケースに応じて利用してください。

### 公開するURLを変更したい

デフォルトで公開される URL は、 `www` のサブドメインを持ちます。任意のサブドメイン名を指定をすることでユーザが認知しやすい公開用 URL でアクセスできるようになります。

QVS config に以下のパラメータを追加し、アプリケーションのリポジトリにコミットします。

コミット後、Pipeline および Task の更新のため、再度 4. Pipeline / Task 作成 の実施をしてください。

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/adapters/azure/serverless/staticSite/frontend
    params:
      appName: $(params.appName)
      azureSubscriptionId: $(params.azureSubscriptionId)
      azureResourceGroupName: $(params.azureResourceGroupName)
      azureDnsZoneName: $(params.azureDnsZoneName)
      relativeRecordSetName: $(params.relativeRecordSetName) # 追加する
```

Deployment Config に以下のパラメータを追加します。例として `my-app`を指定しています。

```yaml
relativeRecordSetName: my-app
```

### 別のロケーションにデプロイしたい

Webアプリがデプロイされるデフォルトのロケーションは `East Asia` です。
デプロイするロケーションを指定することが可能になっており、レイテンシー改善やリーガル対応のために利用することができます。
指定可能なロケーションについては [Frontend Adapter](../../../../../adapters/azure/serverless/staticSite/frontend##infrastructure-parameters) の `azureStaticSiteLocation` をご確認ください。

> **NOTE**
> 別のロケーションにデプロイする際、既にデプロイ済みのWebアプリケーションがある場合、デプロイはできません。
> もし別のロケーションにデプロイを行いたい場合は、アダプタで作成したリソースの削除した後に再度デプロイを行ってください。[参考](https://docs.valuestream.qmonus.net/guide/resource-deletion.html#%E3%83%86%E3%82%99%E3%83%95%E3%82%9A%E3%83%AD%E3%82%A4%E3%81%97%E3%81%9F%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%89%8A%E9%99%A4)

QVS config に以下のパラメータを追加し、アプリケーションのリポジトリにコミットします。

コミット後、Pipeline および Task の更新のため、再度 4. Pipeline / Task 作成 の実施をしてください。

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/adapters/azure/serverless/staticSite/frontend
    params:
      appName: $(params.appName)
      azureStaticSiteLocation: $(params.azureStaticSiteLocation) # 追加する
      azureSubscriptionId: $(params.azureSubscriptionId)
      azureResourceGroupName: $(params.azureResourceGroupName)
      azureDnsZoneName: $(params.azureDnsZoneName)
```

Deployment Config にパラメータを追加します。例として `Central US` を指定しています。

```yaml
azureStaticSiteLocation: Central US
```



上記含め、そのほか指定可能なパラメータについては [こちら](https://github.com/qmonus/official-cloud-native-adapters-internal/tree/main/adapters/azure/serverless/staticSite/frontend)をご参照ください。