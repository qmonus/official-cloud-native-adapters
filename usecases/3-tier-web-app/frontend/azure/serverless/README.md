# Frontend Adapter の使い方

[Frontend Adapter](../../../../../adapters/azure/serverless/staticSite/frontend/README.md) は、 [Shared Infrastructure Adapter](../../../../../adapters/azure/serverless/staticSite/frontend/sharedInfrastructure/README.md) によってデプロイされた共有リソースと組み合わせて利用することで、Azure Static Web Apps を利用して静的Webアプリケーションを迅速にデプロイすることができます。
このドキュメントではお手持ちのアプリケーションを利用して、Azure 上に静的 Web アプリケーションをデプロイする方法を記載しています。またユースケースに応じた設定変更についても記載しています。

本ドキュメントはチュートリアル実施済みのユーザを対象としています。必要に応じて適宜[チュートリアル](https://docs.valuestream.qmonus.net/tutorials/)を参照してください。

## 事前準備

Adapter を利用して静的 Web アプリケーションをデプロイするにあたり、以下の項目をご準備ください。

1. サービスプリンシパル の作成
    Frontend Adapter を利用してWebアプリケーションをデプロイする際、Azure Static Web Apps を利用するための権限が付与されたサービスプリンシパル を作成する必要があります。
    「[ポータルで Azure AD アプリとサービス プリンシパルを作成する](https://learn.microsoft.com/ja-jp/azure/active-directory/develop/howto-create-service-principal-portal) 」と「[Frontend Adapter](../../../../../adapters/azure/serverless/staticSite/frontend/README.md)」 を参考にして必要な権限を付与したサービスプリンシパルを作成するか、以下に示している CLI での作成例を参考にしてください。

    Bash 環境でAzure CLIを利用してサービスプリンシパルを作成する場合の手順を示します。作成するサービスプリンシパルの権限は以下になります。

      - スコープ: サブスクリプション
      - ロール: 共同作成者

    Azure CLI が必要なため「[Azure Cloud Shellを利用する](https://learn.microsoft.com/ja-jp/azure/cloud-shell/quickstart?tabs=azurecli)」、もしくは「[Azure CLIをローカル端末にインストール](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli)」を実施してから手順を実施してください。

    1. Azureテナントにサインインします

        ※Azure Cloudshell の場合は不要です。
        [Azure CLI を使用してサインインする](https://learn.microsoft.com/ja-jp/cli/azure/authenticate-azure-cli#authentication-methods) に基づき認証を行います。詳細は公式ドキュメントをご参照ください。

        ```bash
        az login
        ```

    1. サブスクリプションIDを取得します。
        サービスプリンシパルを作成するサブスクリプションと、権限のスコープ指定のためにサブスクリプションIDを取得し表示します。

        ```bash
        SUBSCID=$(az account show --query id --output tsv)
        echo ${SUBSCID}
        ```

        このとき、必ず表示された値を別途保存してください。Environmentリソースの作成時に利用します。

    1. 共同作成者ロールのサービスプリンシパルをサブスクリプションスコープで作ります
        `<YOUR_SERVICE_PRICIPAL_NAME>` は自身が登録したいサービスプリンシパル名に変更してください

        ```bash
        az ad sp create-for-rbac -n <YOUR_SERVICE_PRICIPAL_NAME> --role Contributor --scopes /subscriptions/${SUBSCID} /subscriptions/${SUBSCID}
        ```

        このとき以下の値が表示されます。Value Stream の Environmentリソースの作成時に利用するため必ず各フィールドの値を別途保存してください。

        - `appId`: アプリケーションID
        - `password`: サービスプリンシパルのシークレットキー
        - `tenant`: テナントID

        もし保存し忘れてしまった場合は同じコマンドを再実行することで password が再生成されます。

    1. サービスプリンシパルが作成されたことを確認します

        ```bash
        az ad sp list --display-name <YOUR_SERVICE_PRICIPAL_NAME>
        ```

1. 共有リソースの作成
    Frontend Adapter を利用するには事前に必要なリソースがあります。

    - Azure DNS Zone を作成する（すでに作成済みの場合はスキップします）

## Value Stream によるリソースデプロイ

1. QVS Config の登録

    QVS Config をアプリケーションのリポジトリに登録してください。リポジトリに最小パラメータで利用できる [qvs.yaml](./qvsconfig/qvs.yaml) と、全パラメータを設定する [full_params_qvs.yaml](./qvsconfig/full_params_qvs.yaml) を配置しているので適宜利用してください。
    ユースケースに応じて設定変更は [こちら](#ユースケースに応じた設定変更) をご参照ください。

    以下にデフォルト設定の QVS Config を示します。

    ```bash
    params:
      - name: appName
        type: string
      - name: azureSubscriptionId
        type: string
      - name: azureResourceGroupName
        type: string
      - name: azureDnsZoneResourceGroupName
        type: string
      - name: azureDnsZoneName
        type: string

    modules:
      - name: qmonus.net/adapter/official
        revision: v0.17.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/azure/serverless/staticSite/frontend
        params:
          appName: $(params.appName)
          azureSubscriptionId: $(params.azureSubscriptionId)
          azureResourceGroupName: $(params.azureResourceGroupName)
          azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
          azureDnsZoneName: $(params.azureDnsZoneName)
    ```

1. Value Stream リソースの作成

   Repository、Application、Environment、Deployment などの Value Stream リソースを作成して登録してください。
   Environmentリソース作成時、Azure の Provisioning Targetでは `Public` を選択してください。

1. Pipeline/Tasks の生成

    Qmonus Values Stream の Assemblyline のページにある `COMPILE AND APPLY PIPELINE/TASK` 機能を利用して Pipeline/Tasks を生成してください。

1. AssemblyLine の作成と登録、および実行

    AssemblyLineを作成して Value Stream に登録し、実行してください。
    [assemblyline.yaml](./assemblyline.yaml) ファイルを必要に応じて参照し、ファイル中のアプリケーション名や Deployment などを指定する <YOUR_XXXX> のパラメータは、自身の環境に合わせて置き換えてください。


## ユースケースに応じた設定変更

デプロイするアプリケーションを公開する際に利用できる Optional なパラメータが2つあります。ユースケースに応じて利用してください。


### 公開するURLを変更したい

デフォルトで公開される URL は、 `www` のサブドメインを持ちます。任意のサブドメイン名を指定をすることでユーザが認知しやすい公開用 URL でアクセスできるようになります。

1. QVS config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS config は [custom_domain.yaml](./qvsconfig/custom_domain.yaml) を利用してください。以下にデフォルトとの差分を示します。

    ```diff
     params:
       - name: appName
         type: string
       - name: azureSubscriptionId
         type: string
       - name: azureResourceGroupName
         type: string
       - name: azureDnsZoneResourceGroupName
         type: string
       - name: azureDnsZoneName
         type: string
    +  - name: relativeRecordSetName
    +    type: string

     modules:
       - name: qmonus.net/adapter/official
         revision: v0.17.0

     designPatterns:
       - pattern: qmonus.net/adapter/official/adapters/azure/serverless/staticSite/frontend
         params:
           appName: $(params.appName)
           azureSubscriptionId: $(params.azureSubscriptionId)
           azureResourceGroupName: $(params.azureResourceGroupName)
           azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
           azureDnsZoneName: $(params.azureDnsZoneName)
    +      relativeRecordSetName: $(params.relativeRecordSetName)
    ```


2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルと登録を実施してください。

3. Value Stream の画面から Deployment Config に以下のパラメータを追加します。例として `my-app`を指定しています。

    ```yaml
    relativeRecordSetName: my-app
    ```

4. AssemblyLineを実行します。
    実行が成功するとAzure Static Web AppsでStatic Siteが作成され、公開されるURLは `my-app` のサブドメインを持つようになります。
    Assemblyline Results に表示されている `publicUrl` を確認し、アクセスできることを確認してください。


### 別のロケーションにデプロイしつつ公開するURLも変更する

Webアプリがデプロイされるデフォルトのロケーションは `East Asia` です。
デプロイするロケーションを指定することが可能になっており、レイテンシー改善やリーガル対応のために利用することができます。
指定可能なロケーションについては [Frontend Adapter](../../../../../adapters/azure/serverless/staticSite/frontend##infrastructure-parameters) の `azureStaticSiteLocation` をご確認ください。

> **NOTE**
> すでにデプロイされている同名のWebアプリケーションがあると新規デプロイはできません。
> 別のロケーションにデプロイを行いたい場合は、まずアダプタを使って作成したリソースを削除しその後に再度デプロイを実行してください。[参考:デプロイしたリソースの削除](https://docs.valuestream.qmonus.net/guide/resource-deletion.html#%E3%83%86%E3%82%99%E3%83%95%E3%82%9A%E3%83%AD%E3%82%A4%E3%81%97%E3%81%9F%E3%83%AA%E3%82%BD%E3%83%BC%E3%82%B9%E3%81%AE%E5%89%8A%E9%99%A4)

1. QVS config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS config は [custom_location.yaml](./qvsconfig/custom_location.yaml) を利用してください。以下にデフォルトとの差分を示します。

    ```diff
     params:
       - name: appName
         type: string
    +  - name: azureStaticSiteLocation
    +    type: string
       - name: azureSubscriptionId
         type: string
       - name: azureResourceGroupName
         type: string
       - name: azureDnsZoneResourceGroupName
         type: string
       - name: azureDnsZoneName
         type: string
    +  - name: relativeRecordSetName
    +    type: string

    modules:
       - name: qmonus.net/adapter/official
         revision: v0.17.0

     designPatterns:
       - pattern: qmonus.net/adapter/official/adapters/azure/serverless/staticSite/frontend
         params:
           appName: $(params.appName)
    +      azureStaticSiteLocation: ${params.azureStaticSiteLocation)
           azureSubscriptionId: $(params.azureSubscriptionId)
           azureResourceGroupName: $(params.azureResourceGroupName)
           azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
           azureDnsZoneName: $(params.azureDnsZoneName)
    +      relativeRecordSetName: $(params.relativeRecordSetName)
    ```


2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルと登録を実施してください。

3. Value Stream の画面から Deployment Config にパラメータを追加します。例として `Central US` を指定しています。

      ```yaml
      azureStaticSiteLocation: Central US
      relativeRecordSetName: my-app-us
      ```

4. Assemblyline を実行します。
    実行が成功するとAzure Static Web AppsでStatic Siteが作成されます。
    Azure Portal から Azure Static Web Apps に移動し、デプロイされているロケーションが `Central US` に、公開されるURLが `my-app-us` のサブドメインを持っていることを確認します。



ユースケースを組み合わせて利用することもできます。そのほか指定可能なパラメータについては [Frontend Adapter](https://github.com/qmonus/official-cloud-native-adapters-internal/tree/main/adapters/azure/serverless/staticSite/frontend)をご参照ください。

### アプリケーションの環境変数を設定したい

デプロイするアプリケーションに任意の環境変数を設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS config は [qvs_env.yaml](./qvsconfig/qvs_env.yaml) を利用してください。以下にデフォルトとの差分を示します。
   [qvs_env.yaml](./qvsconfig/qvs_env.yaml) のENV1, ENV2部分は、設定したい環境変数に置き換えてご利用ください。

    ```diff
     params:
       - name: appName
         type: string
       - name: azureSubscriptionId
         type: string
       - name: azureResourceGroupName
         type: string
       - name: azureDnsZoneResourceGroupName
         type: string
       - name: azureDnsZoneName
         type: string
    +  - name: env1
    +    type: string
    +  - name: env2
    +    type: string

     modules:
       - name: qmonus.net/adapter/official
         revision: v0.19.0

     designPatterns:
       - pattern: qmonus.net/adapter/qmonus.net/adapter/official/adapters/azure/serverless/staticSite/frontend  
         params:
           appName: $(params.appName)
           azureSubscriptionId: $(params.azureSubscriptionId)
           azureResourceGroupName: $(params.azureResourceGroupName)
           azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
           azureDnsZoneName: $(params.azureDnsZoneName)
    +      environmentVariables:
    +        ENV1: $(params.env1)
    +        ENV2: $(params.env2)
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルを実施してください。

3. QVS の画面から Deployment Config にパラメータを追加します。
  以下の例を参考にしてください。

    ```yaml
    env1: hoge
    env2: fuga
    ```