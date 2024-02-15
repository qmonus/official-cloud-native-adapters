# Frontend Adapter の使い方

[Frontend Adapter](../../../../../adapters/gcp/serverless/staticSite/frontend/README.md) は、Firebase Hosting を利用して静的Webアプリケーションを迅速にデプロイすることができます。
このドキュメントではお手持ちのアプリケーションを利用して、Firebase 上に静的 Web アプリケーションをデプロイする方法を記載しています。またユースケースに応じた設定変更についても記載しています。

本ドキュメントはチュートリアル実施済みのユーザを対象としています。必要に応じて適宜[チュートリアル](https://docs.valuestream.qmonus.net/tutorials/)を参照してください。

## 事前準備

Adapter を利用して静的 Web アプリケーションをデプロイするにあたり、以下の項目をご準備ください。

1. Cloud DNS ゾーンの作成

    Frontend Adapter を利用するために事前に必要な DNS ゾーンを [Frontend Adapter のドキュメント](../../../../../adapters/gcp/serverless/staticSite/frontend/README.md#prerequisites) を参考にして作成してください。

1. サービスアカウントの作成

    Frontend Adapter を利用して Web アプリケーションをデプロイする際、Firebase および Google Cloud のサービスを利用するための権限が付与されたサービスアカウントを作成する必要があります。
    Google Cloud の [公式ドキュメント](https://cloud.google.com/iam/docs/service-accounts-create?hl=ja) と [Frontend Adapter のドキュメント](../../../../../adapters/gcp/serverless/staticSite/frontend/README.md#prerequisites) を参考にして、必要な権限を付与したサービスアカウントを作成してください。

    1. サービスアカウントキーを作成します。

        [公式ドキュメント](https://cloud.google.com/iam/docs/creating-managing-service-account-keys?hl=ja) を参考にして、作成したサービスアカウントのサービスアカウントキーを作成してください。Environment リソースの作成時に利用します。

## Value Stream によるリソースデプロイ

1. QVS Config の登録

    QVS Config をアプリケーションのリポジトリに登録してください。リポジトリに最小パラメータで利用できる [qvs.yaml](./qvsconfig/qvs.yaml) と、全パラメータを設定する [full_params_qvs.yaml](./qvsconfig/full_params_qvs.yaml) を配置しているので適宜利用してください。
    ユースケースに応じて設定変更は [こちら](#ユースケースに応じた設定変更) をご参照ください。

    以下にデフォルト設定の QVS Config を示します。

    ```bash
    params:
      - name: appName
        type: string
      - name: gcpProjectId
        type: string
      - name: dnsZoneProjectId
        type: string
      - name: dnsZoneName
        type: string
      - name: gcpFirebaseHostingSiteId
        type: string
      - name: gcpFirebaseHostingCustomDomainName
        type: string

    modules:
      - name: qmonus.net/adapter/official
        revision: v0.23.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/gcp/serverless/staticSite/frontend
        params:
          appName: $(params.appName)
          gcpProjectId: $(params.gcpProjectId)
          dnsZoneProjectId: $(params.dnsZoneProjectId)
          dnsZoneName: $(params.dnsZoneName)
          gcpFirebaseHostingSiteId: $(params.gcpFirebaseHostingSiteId)
          gcpFirebaseHostingCustomDomainName: $(params.gcpFirebaseHostingCustomDomainName)
    ```

1. Value Stream リソースの作成

    Repository、Application、Environment、Deployment などの QVS リソースを作成して登録してください。
    - Environment リソース作成時に、Google Cloud の Provisioning Target を登録してください。
    - Deployment リソース作成時に、Google Cloud の Credentials を登録してください。
      - Google Cloud の Credential として、作成したサービスアカウントキーを登録してください。

1. Pipeline/Tasks の生成

    Qmonus Values Stream の Assemblyline のページにある `COMPILE AND APPLY PIPELINE/TASK` 機能を利用して Pipeline/Tasks を生成してください。

1. AssemblyLine の作成と登録、および実行

    AssemblyLine を作成して QVS に登録し、実行してください。
    必要に応じて [assemblyline.yaml](./assemblyline.yaml) ファイルを参照し、ファイル中の Application や Deployment などを指定する <YOUR_XXXX> のパラメータは、自身の環境に合わせて置き換えてください。


## ユースケースに応じた設定変更

デプロイするアプリケーションを公開する際に利用できる Optional なパラメータがあります。ユースケースに応じて利用してください。


### アプリケーションの環境変数を設定したい

デプロイするアプリケーションに任意の環境変数を設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS config は [qvs_env.yaml](./qvsconfig/qvs_env.yaml) を利用してください。以下にデフォルトとの差分を示します。
   [qvs_env.yaml](./qvsconfig/qvs_env.yaml) のENV1, ENV2部分は、設定したい環境変数に置き換えてご利用ください。

    ```diff
     params:
       - name: appName
         type: string
       - name: gcpProjectId
         type: string
       - name: dnsZoneProjectId
         type: string
       - name: dnsZoneName
         type: string
       - name: gcpFirebaseHostingSiteId
         type: string
       - name: gcpFirebaseHostingCustomDomainName
         type: string
    +  - name: env1
    +    type: string
    +  - name: env2
    +    type: string

     modules:
       - name: qmonus.net/adapter/official
         revision: v0.23.0

     designPatterns:
       - pattern: qmonus.net/adapter/qmonus.net/adapter/official/adapters/gcp/serverless/staticSite/frontend  
         params:
           appName: $(params.appName)
           gcpProjectId: $(params.gcpProjectId)
           dnsZoneProjectId: $(params.dnsZoneProjectId)
           dnsZoneName: $(params.dnsZoneName)
           gcpFirebaseHostingSiteId: $(params.gcpFirebaseHostingSiteId)
           gcpFirebaseHostingCustomDomainName: $(params.gcpFirebaseHostingCustomDomainName)
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

そのほか指定可能なパラメータについては [Frontend Adapter](../../../../../adapters/gcp/serverless/staticSite/frontend/README.md)をご参照ください。