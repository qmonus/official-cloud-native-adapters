# API Backend Adapter の使い方

[API Backend Adapter](../../../../../adapters/gcp/container/kubernetes/apiBackend/README.md) は、 [Shared Infrastructure Adapter](../../../../../adapters/gcp/container/kubernetes/apiBackend/sharedInfrastructure/README.md) によってデプロイされた共有リソースと組み合わせて利用することで、Google Kubernetes Engine（GKE）を利用して API バックエンドアプリケーションを迅速にデプロイできます。
このドキュメントではお手持ちのアプリケーションを利用して、Google Cloud 上に API バックエンドアプリケーションをデプロイする方法を記載しています。またユースケースに応じた設定変更について記載しています。

本ドキュメントはチュートリアル実施済みのユーザを対象としています。必要に応じて適宜 [チュートリアル](https://docs.valuestream.qmonus.net/tutorials/) を参照してください。

## 事前準備

Adapter を利用して API バックエンドアプリケーションをデプロイするにあたり、以下の項目を準備してください。

1. 共有リソースの作成（すでに作成済みの場合はスキップします）

    API Backend Adapter を利用するには事前に必要なリソースがあります。

    - Cloud DNS ゾーン
      - [API Backend Adapter](../../../../../adapters/gcp/container/kubernetes/apiBackend/README.md#prerequisites) を参照して DNS ゾーンを作成してください。
    - [Shared Infrastructure Adapter](../../../../../adapters/gcp/container/kubernetes/apiBackend/sharedInfrastructure/README.md) で作成されるリソース
      - デフォルト設定で利用できる Shared Infrastructure Adapter の QVS Config である [qvs_sharedInfrastructure.yaml](./qvsconfig/qvs_sharedInfrastructure.yaml) をリポジトリに配置しているので、適宜利用してください。以下にデフォルト設定の QVS Config を示します。
      ```yaml
      params:
        - name: appName
          type: string
        - name: gcpProjectId
          type: string

      modules:
        - name: github.com/qmonus/official-cloud-native-adapters
          revision: v0.23.0

      designPatterns:
        - pattern: qmonus.net/adapter/official/adapters/gcp/container/kubernetes/apiBackend/sharedInfrastructure
          params:
            appName: $(params.appName)
            gcpProjectId: $(params.gcpProjectId)
      ```
      - Shared Infrastructure Adapter を利用するための Repository、Application、Environment、Deployment などの QVS リソースを作成して登録してください。
        - Environment リソース作成時は、Google Cloud の Provisioning Target を登録してください。
      - Shared Infrastructure Adapter を利用するための Pipeline/Task、AssemblyLine を作成して登録してください。
        - 必要に応じて [assemblyline_sharedInfrastructure.yaml](./assemblyline/assemblyline_sharedInfrastructure.yaml) ファイルを参照し、ファイル中の Application や Deployment などを指定する <YOUR_XXXX> のパラメータは、自身の環境に合わせて置き換えてください。
      - AssemblyLine を実行してください。

1. サービスアカウントの作成

    API Backend Adapter を利用して Web アプリケーションをデプロイする際、Google Cloud のサービスを利用するための権限が付与されたサービスアカウントを作成する必要があります。
    Google Cloud の [公式ドキュメント](https://cloud.google.com/iam/docs/service-accounts-create?hl=ja) と [API Backend Adapter のドキュメント](../../../../../adapters/gcp/container/kubernetes/apiBackend/README.md#prerequisites) を参考にして、必要な権限を付与したサービスアカウントを作成してください。

    1. サービスアカウントキーを作成します。

        [公式ドキュメント](https://cloud.google.com/iam/docs/creating-managing-service-account-keys?hl=ja) を参考にして、作成したサービスアカウントのサービスアカウントキーを作成してください。Environment リソースの作成時に利用します。

## Value Stream によるリソースデプロイ

1. QVS Config の登録

    QVS Config をアプリケーションのリポジトリに登録してください。最少パラメータで利用できる [qvs.yaml](./qvsconfig/qvs.yaml) と、全パラメータを設定する [full_params_qvs.yaml](./qvsconfig/full_params_qvs.yaml) をリポジトリに配置しているので適宜利用してください。
    ユースケースに応じた設定変更は [こちら](#ユースケースに応じた設定変更) を参照してください。

    以下にデフォルト設定の QVS Config を示します。

    ```yaml
    params:
      - name: appName
        type: string
      - name: gcpProjectId
        type: string
      - name: dnsZoneProjectId
        type: string
      - name: dnsZoneName
        type: string
      - name: dnsARecordSubdomain
        type: string
      - name: mysqlInstanceId
        type: string
      - name: mysqlDatabaseName
        type: string
      - name: mysqlUserName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: mysqlInstanceIpAddress
        type: string

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.23.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/gcp/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          gcpProjectId: $(params.gcpProjectId)
          dnsZoneProjectId: $(params.dnsZoneProjectId)
          dnsZoneName: $(params.dnsZoneName)
          dnsARecordSubdomain: $(params.dnsARecordSubdomain)
          mysqlInstanceId: $(params.mysqlInstanceId)
          mysqlDatabaseName: $(params.mysqlDatabaseName)
          mysqlUserName: $(params.mysqlUserName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          mysqlInstanceIpAddress: $(params.mysqlInstanceIpAddress)
    ```

1. Value Stream リソースの作成

    Repository、Application、Environment、Deployment などの QVS リソースを作成して登録してください。
    - Environment リソース作成時に、Google Cloud と Kubernetes の Provisioning Target を登録してください。
    - Deployment リソース作成時に、Google Cloud と Kubernetes の Credentials を登録してください。
      - Google Cloud の Credential として、作成したサービスアカウントキーを登録してください。
      - Kubernetes の Credential として、Shared Infrastructure Adapter によって Secret Manager に保存された kubeconfig を登録してください。

1. Pipeline/Task の生成

    Qmonus Value Stream の AssemblyLine のページにある `COMPILE AND APPLY PIPELINE/TASK` 機能を利用して Pipeline/Task を生成してください。

1. AssemblyLine の作成と登録、および実行

    AssemblyLine を作成して QVS に登録し、実行してください。
    必要に応じて [assemblyline_apiBackend.yaml](./assemblyline/assemblyline_apiBackend.yaml) ファイルを参照し、ファイル中の Application や Deployment などを指定する <YOUR_XXXX> のパラメータは、自身の環境に合わせて置き換えてください。

## ユースケースに応じた設定変更

デプロイするアプリケーションを公開する際に利用できる Optional なパラメータがあります。ユースケースに応じて利用してください。

### アプリケーションの引数を設定したい

デプロイするアプリケーションに任意の引数を設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS Config は [qvs_args.yaml](./qvsconfig/qvs_args.yaml) を利用してください。以下にデフォルトとの差分を示します。

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
      - name: dnsARecordSubdomain
        type: string
      - name: mysqlInstanceId
        type: string
      - name: mysqlDatabaseName
        type: string
      - name: mysqlUserName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: mysqlInstanceIpAddress
        type: string
    + - name: args
    +   type: array

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.23.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/gcp/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          gcpProjectId: $(params.gcpProjectId)
          dnsZoneProjectId: $(params.dnsZoneProjectId)
          dnsZoneName: $(params.dnsZoneName)
          dnsARecordSubdomain: $(params.dnsARecordSubdomain)
          mysqlInstanceId: $(params.mysqlInstanceId)
          mysqlDatabaseName: $(params.mysqlDatabaseName)
          mysqlUserName: $(params.mysqlUserName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          mysqlInstanceIpAddress: $(params.mysqlInstanceIpAddress)
    +     args: ["$(params.args[*])"]
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

3. QVS の画面から Deployment Config にパラメータを追加してください。

    以下の例の通り、複数の引数を設定する場合、カンマ区切りで引数を指定します。

    ```yaml
    args: "--foo,--bar"
    ```

### アプリケーションの環境変数を設定したい

デプロイするアプリケーションに任意の環境変数を設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS Config は [qvs_env.yaml](./qvsconfig/qvs_env.yaml) を利用してください。以下にデフォルトとの差分を示します。
    [qvs_env.yaml](./qvsconfig/qvs_env.yaml) のENV1, ENV2部分は、設定したい環境変数に置き換えて利用してください。

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
      - name: dnsARecordSubdomain
        type: string
      - name: mysqlInstanceId
        type: string
      - name: mysqlDatabaseName
        type: string
      - name: mysqlUserName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: mysqlInstanceIpAddress
        type: string
    + - name: env1
    +   type: string
    + - name: env2
    +   type: string

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.23.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/gcp/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          gcpProjectId: $(params.gcpProjectId)
          dnsZoneProjectId: $(params.dnsZoneProjectId)
          dnsZoneName: $(params.dnsZoneName)
          dnsARecordSubdomain: $(params.dnsARecordSubdomain)
          mysqlInstanceId: $(params.mysqlInstanceId)
          mysqlDatabaseName: $(params.mysqlDatabaseName)
          mysqlUserName: $(params.mysqlUserName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          mysqlInstanceIpAddress: $(params.mysqlInstanceIpAddress)
    +     environmentVariables:
    +       ENV1: $(params.env1)
    +       ENV2: $(params.env2)
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

3. QVS の画面から Deployment Config にパラメータを追加してください。

    以下の例を参考にしてください。

    ```yaml
    env1: hoge
    env2: fuga
    ```

### アプリケーションのシークレットを設定したい

デプロイするアプリケーションに任意のシークレットを設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS Config は [qvs_secret.yaml](./qvsconfig/qvs_secret.yaml) を利用してください。以下にデフォルトとの差分を示します。
    [qvs_secret.yaml](./qvsconfig/qvs_secret.yaml) のSECRET1, SECRET2部分は、設定したい環境変数に置き換えて利用してください。

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
      - name: dnsARecordSubdomain
        type: string
      - name: mysqlInstanceId
        type: string
      - name: mysqlDatabaseName
        type: string
      - name: mysqlUserName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: mysqlInstanceIpAddress
        type: string
    + - name: secret1
    +   type: secret
    + - name: secret2
    +   type: secret

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.23.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/gcp/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          gcpProjectId: $(params.gcpProjectId)
          dnsZoneProjectId: $(params.dnsZoneProjectId)
          dnsZoneName: $(params.dnsZoneName)
          dnsARecordSubdomain: $(params.dnsARecordSubdomain)
          mysqlInstanceId: $(params.mysqlInstanceId)
          mysqlDatabaseName: $(params.mysqlDatabaseName)
          mysqlUserName: $(params.mysqlUserName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          mysqlInstanceIpAddress: $(params.mysqlInstanceIpAddress)
    +     secrets:
    +       SECRET1: $(params.secret1)
    +       SECRET2: $(params.secret2)
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

3. secret1, secret2のキーをDeployment Secret画面から設定してください。Secretの登録方法については [Secretの登録](https://docs.valuestream.qmonus.net/guide/secrets.html) を参照してください。

### アプリケーションの公開範囲を制限したい

デプロイするアプリケーションにアクセスできるソースIPアドレスを制限できます。制限しない場合は、インターネットの全てのIPアドレスからのアクセスが許可されます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS Config は [qvs_allowedSourceIps.yaml](./qvsconfig/qvs_allowedSourceIps.yaml) を利用してください。以下にデフォルトとの差分を示します。

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
      - name: dnsARecordSubdomain
        type: string
      - name: mysqlInstanceId
        type: string
      - name: mysqlDatabaseName
        type: string
      - name: mysqlUserName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: mysqlInstanceIpAddress
        type: string
    + - name: cloudArmorAllowedSourceIps
    +   type: array

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.23.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/gcp/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          gcpProjectId: $(params.gcpProjectId)
          dnsZoneProjectId: $(params.dnsZoneProjectId)
          dnsZoneName: $(params.dnsZoneName)
          dnsARecordSubdomain: $(params.dnsARecordSubdomain)
          mysqlInstanceId: $(params.mysqlInstanceId)
          mysqlDatabaseName: $(params.mysqlDatabaseName)
          mysqlUserName: $(params.mysqlUserName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          mysqlInstanceIpAddress: $(params.mysqlInstanceIpAddress)
    +     cloudArmorAllowedSourceIps: ["$(params.cloudArmorAllowedSourceIps[*])"]
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

3. QVS の画面から Deployment Config にパラメータを追加してください。

    以下の例の通り、複数のIPアドレスを設定する場合、カンマ区切りで引数を指定します。
    特定のIPアドレス範囲を設定する場合、CIDR表記で指定できます。

    ```yaml
    cloudArmorAllowedSourceIps: 192.168.0.1,172.16.0.0/12
    ```

そのほか指定可能なパラメータについては [API Backend Adapter](../../../../../adapters/gcp/container/kubernetes/apiBackend/README.md)を参照してください。
