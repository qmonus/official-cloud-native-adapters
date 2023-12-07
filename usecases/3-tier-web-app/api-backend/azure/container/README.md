# API Backend Adapter の使い方

[API Backend Adapter](../../../../../adapters/azure/container/kubernetes/apiBackend/README.md) は、 [Shared Infrastructure Adapter](../../../../../adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure/README.md) によってデプロイされた共有リソースと組み合わせて利用することで、Azure Kubernetes Service（AKS）を利用して API バックエンドアプリケーションを迅速にデプロイできます。
このドキュメントではお手持ちのアプリケーションを利用して、Azure 上に API バックエンドアプリケーションをデプロイする方法を記載しています。またユースケースに応じた設定変更について記載しています。

本ドキュメントはチュートリアル実施済みのユーザを対象としています。必要に応じて適宜[チュートリアル](https://docs.valuestream.qmonus.net/tutorials/)を参照してください。

## 事前準備

Adapter を利用して API バックエンドアプリケーションをデプロイするにあたり、以下の項目を準備してください。

1. 共有リソースの作成（すでに作成済みの場合はスキップします）

    API Backend Adapter を利用するには事前に必要なリソースがあります。

    - Azure DNS Zone
      - [Shared Infrastructure Adapter](../../../../../adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure/README.md) を参照して DNS ゾーンを作成してください。
    - [Shared Infrastructure Adapter](../../../../../adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure/README.md) で作成されるリソース
      - デフォルト設定で利用できる Shared Infrastructure Adapter の QVS Config である [qvs_sharedInfrastructure.yaml](./qvsconfig/qvs_sharedInfrastructure.yaml) をリポジトリに配置しているので、適宜利用してください。以下にデフォルト設定の QVS Config を示します。
      ```bash
      params:
        - name: appName
          type: string
        - name: azureTenantId
          type: string
        - name: azureSubscriptionId
          type: string
        - name: azureResourceGroupName
          type: string
        - name: azureDnsZoneResourceGroupName
          type: string
        - name: dnsZoneName
          type: string
        - name: keyVaultAccessAllowedObjectIds
          type: array

      modules:
        - name: github.com/qmonus/official-cloud-native-adapters
          revision: v0.20.0

      designPatterns:
        - pattern: qmonus.net/adapter/official/adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure
          params:
            appName: $(params.appName)
            azureTenantId: $(params.azureTenantId)
            azureSubscriptionId: $(params.azureSubscriptionId)
            azureResourceGroupName: $(params.azureResourceGroupName)
            azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
            dnsZoneName: $(params.dnsZoneName)
            keyVaultAccessAllowedObjectIds: ["$(params.keyVaultAccessAllowedObjectIds[*])"]
      ```
      - Shared Infrastructure Adapter を利用するための Repository、Application、Environment、Deployment などの QVS リソースを作成して登録してください。
        - Environment リソース作成時は、Azure の Provisioning Target を登録してください。Azure の Provisioning Target では `Public` を選択してください。
      - Shared Infrastructure Adapter を利用するための Pipeline/Task、AssemblyLine を作成して登録してください。
        - 必要に応じて [assemblyline_sharedInfrastructure.yaml](./assemblyline/assemblyline_sharedInfrastructure.yaml) ファイルを参照し、ファイル中の Application や Deployment などを指定する <YOUR_XXXX> のパラメータは、自身の環境に合わせて置き換えてください。
      - AssemblyLine を実行してください。

1. サービスプリンシパルの作成

    API Backend Adapter を利用して Web アプリケーションをデプロイする際、AKS を利用するための権限が付与されたサービスプリンシパルを作成する必要があります。
    「[Azure 公式ドキュメントの作成手順](https://learn.microsoft.com/ja-jp/azure/active-directory/develop/howto-create-service-principal-portal) 」と「[Shared Infrastructure Adapter のドキュメント](../../../../../adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure/README.md)」を参考にして、必要な権限を付与したサービスプリンシパルを作成するか、以下に示している CLI での作成例を参考にしてください。

    Bash 環境で Azure CLI を利用してサービスプリンシパルを作成する場合の手順を示します。作成するサービスプリンシパルの権限は以下になります。

    - スコープ: サブスクリプション
    - ロール: 共同作成者

    Azure CLI が必要なため、[Azure Cloud Shell を利用する](https://learn.microsoft.com/ja-jp/azure/cloud-shell/get-started)、もしくは [Azure CLI をローカル端末にインストール](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli)して手順を実施してください。

    1. Azure テナントにサインインします。

        ※Azure Cloud Shell の場合は不要です。
        [Azure CLI を使用してサインイン](https://learn.microsoft.com/ja-jp/cli/azure/authenticate-azure-cli#authentication-methods)します。詳細は公式ドキュメントを参照してください。

        ```bash
        az login
        ```

    1. サブスクリプション ID を取得します。

        サービスプリンシパルを作成するサブスクリプションと、権限のスコープ指定のためにサブスクリプション ID を取得し表示します。

        ```bash
        SUBSCID=$(az account show --query id --output tsv)
        echo ${SUBSCID}
        ```

        このとき、必ず表示された値を別途保存してください。Environment リソースの作成時に利用します。

    1. 共同作成者ロールのサービスプリンシパルをサブスクリプションスコープで作ります。

        `<YOUR_SERVICE_PRINCIPAL_NAME>` は自身が登録したいサービスプリンシパル名に変更してください。

        ```bash
        az ad sp create-for-rbac --display-name <YOUR_SERVICE_PRINCIPAL_NAME> --role Contributor --scopes /subscriptions/${SUBSCID}
        ```

        このとき、必ず表示された `appId`, `password`, `tenant` フィールドの値を別途保存してください。Environment リソースの作成時に利用します。

        - `appId`: アプリケーションID
        - `password`: サービスプリンシパルのシークレットキー
        - `tenant`: テナントID

        もし保存し忘れてしまった場合は同じコマンドを再実行することで password が再生成されます。

    1. サービスプリンシパルが作成されたことを確認します。

        ```bash
        az ad sp list --display-name <YOUR_SERVICE_PRINCIPAL_NAME>
        ```

1. 共有リソースの設定変更と再デプロイ

    作成したサービスプリンシパルにリソースデプロイの権限を追加するために、サービスプリンシパルの情報を共有リソースの設定に登録する必要があります。
    Shared Infrastructure Adapter をデプロイした AssemblyLine で Deployment Config のパラメータを修正し、AssemblyLine を再実行してください。

    1. 作成したサービスプリンシパルのオブジェクトIDを確認します。

        `<YOUR_SERVICE_PRINCIPAL_APP_ID>` は自身が作成したサービスプリンシパルの `appId` に変更してください。

        ```bash
        az ad sp show --id <YOUR_SERVICE_PRINCIPAL_APP_ID> | jq -r .id
        ```

    1. オブジェクトIDの情報を共有リソースの設定に登録します。

        Shared Infrastructure Adapter をデプロイした AssemblyLine の Deployment Config のパラメータ `keyVaultAccessAllowedObjectIds` にオブジェクトIDを追加し、AssemblyLine を実行してください。
        これにより、共有リソースの Azure Key Vault キーコンテナーのアクセスポリシーに、作成したサービスプリンシパルが追加登録されます。

## Value Stream によるリソースデプロイ

1. QVS Config の登録

    QVS Config をアプリケーションのリポジトリに登録してください。リポジトリに最少パラメータで利用できる [qvs.yaml](./qvsconfig/qvs.yaml) と、全パラメータを設定する [full_params_qvs.yaml](./qvsconfig/full_params_qvs.yaml) を配置しているので適宜利用してください。
    ユースケースに応じた設定変更は [こちら](#ユースケースに応じた設定変更) を参照してください。

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
      - name: azureDnsARecordName
        type: string
      - name: azureStaticIpAddress
        type: string
      - name: mysqlCreateDbName
        type: string
      - name: azureKeyVaultKeyContainerName
        type: string
      - name: clusterIssuerName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: dbHost
        type: string
      - name: redisHost
        type: string
      - name: redisPasswordSecretName
        type: string
      - name: host
        type: string

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.20.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/azure/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          azureSubscriptionId: $(params.azureSubscriptionId)
          azureResourceGroupName: $(params.azureResourceGroupName)
          azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
          azureDnsZoneName: $(params.azureDnsZoneName)
          azureDnsARecordName: $(params.azureDnsARecordName)
          azureStaticIpAddress: $(params.azureStaticIpAddress)
          mysqlCreateDbName: $(params.mysqlCreateDbName)
          azureKeyVaultKeyContainerName: $(params.azureKeyVaultKeyContainerName)
          clusterIssuerName: $(params.clusterIssuerName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          dbHost: $(params.dbHost)
          redisHost: $(params.redisHost)
          redisPasswordSecretName: $(params.redisPasswordSecretName)
          host: $(params.host)
   ```

1. Value Stream リソースの作成

    Repository、Application、Environment、Deployment などの QVS リソースを作成して登録してください。
    - Environment リソース作成時に、Azure と Kubernetes の Provisioning Target を登録してください。
      - Azure の Provisioning Target では `Public` を選択してください。
    - Deployment リソース作成時に、Azure と Kubernetes の Credentials を登録してください。
      - Azure の Credential として、サービスプリンシパル作成時に保存した `password` を登録してください。
      - Kubernetes の Credential として、Shared Infrastructure Adapter によって Azure Key Vault に保存された kubeconfig を登録してください。

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
      - name: azureSubscriptionId
        type: string
      - name: azureResourceGroupName
        type: string
      - name: azureDnsZoneResourceGroupName
        type: string
      - name: azureDnsZoneName
        type: string
      - name: azureDnsARecordName
        type: string
      - name: azureStaticIpAddress
        type: string
      - name: mysqlCreateDbName
        type: string
      - name: azureKeyVaultKeyContainerName
        type: string
      - name: clusterIssuerName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: dbHost
        type: string
      - name: redisHost
        type: string
      - name: redisPasswordSecretName
        type: string
      - name: host
        type: string
    + - name: args
    +   type: array

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.20.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/azure/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          azureSubscriptionId: $(params.azureSubscriptionId)
          azureResourceGroupName: $(params.azureResourceGroupName)
          azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
          azureDnsZoneName: $(params.azureDnsZoneName)
          azureDnsARecordName: $(params.azureDnsARecordName)
          azureStaticIpAddress: $(params.azureStaticIpAddress)
          mysqlCreateDbName: $(params.mysqlCreateDbName)
          azureKeyVaultKeyContainerName: $(params.azureKeyVaultKeyContainerName)
          clusterIssuerName: $(params.clusterIssuerName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          dbHost: $(params.dbHost)
          redisHost: $(params.redisHost)
          redisPasswordSecretName: $(params.redisPasswordSecretName)
          host: $(params.host)
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
      - name: azureSubscriptionId
        type: string
      - name: azureResourceGroupName
        type: string
      - name: azureDnsZoneResourceGroupName
        type: string
      - name: azureDnsZoneName
        type: string
      - name: azureDnsARecordName
        type: string
      - name: azureStaticIpAddress
        type: string
      - name: mysqlCreateDbName
        type: string
      - name: azureKeyVaultKeyContainerName
        type: string
      - name: clusterIssuerName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: dbHost
        type: string
      - name: redisHost
        type: string
      - name: redisPasswordSecretName
        type: string
      - name: host
        type: string
    + - name: env1
    +   type: string
    + - name: env2
    +   type: string

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.20.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/azure/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          azureSubscriptionId: $(params.azureSubscriptionId)
          azureResourceGroupName: $(params.azureResourceGroupName)
          azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
          azureDnsZoneName: $(params.azureDnsZoneName)
          azureDnsARecordName: $(params.azureDnsARecordName)
          azureStaticIpAddress: $(params.azureStaticIpAddress)
          mysqlCreateDbName: $(params.mysqlCreateDbName)
          azureKeyVaultKeyContainerName: $(params.azureKeyVaultKeyContainerName)
          clusterIssuerName: $(params.clusterIssuerName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          dbHost: $(params.dbHost)
          redisHost: $(params.redisHost)
          redisPasswordSecretName: $(params.redisPasswordSecretName)
          host: $(params.host)
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
      - name: azureSubscriptionId
        type: string
      - name: azureResourceGroupName
        type: string
      - name: azureDnsZoneResourceGroupName
        type: string
      - name: azureDnsZoneName
        type: string
      - name: azureDnsARecordName
        type: string
      - name: azureStaticIpAddress
        type: string
      - name: mysqlCreateDbName
        type: string
      - name: azureKeyVaultKeyContainerName
        type: string
      - name: clusterIssuerName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: dbHost
        type: string
      - name: redisHost
        type: string
      - name: redisPasswordSecretName
        type: string
      - name: host
        type: string
    + - name: secret1
    +   type: secret
    + - name: secret2
    +   type: secret

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.20.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/azure/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          azureSubscriptionId: $(params.azureSubscriptionId)
          azureResourceGroupName: $(params.azureResourceGroupName)
          azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
          azureDnsZoneName: $(params.azureDnsZoneName)
          azureDnsARecordName: $(params.azureDnsARecordName)
          azureStaticIpAddress: $(params.azureStaticIpAddress)
          mysqlCreateDbName: $(params.mysqlCreateDbName)
          azureKeyVaultKeyContainerName: $(params.azureKeyVaultKeyContainerName)
          clusterIssuerName: $(params.clusterIssuerName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          dbHost: $(params.dbHost)
          redisHost: $(params.redisHost)
          redisPasswordSecretName: $(params.redisPasswordSecretName)
          host: $(params.host)
    +     secrets:
    +       SECRET1: $(params.secret1)
    +       SECRET2: $(params.secret2)
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

3. secret1, secret2のキーをDeployment Secret画面から設定してください。Secretの登録方法については [Secretの登録](https://docs.valuestream.qmonus.net/guide/secrets.html)を参照してください。

### アプリケーションの公開範囲を制限したい

デプロイするアプリケーションにアクセスできるソースIPアドレスを制限できます。制限しない場合は、インターネットの全てのIPアドレスからのアクセスが許可されます。

1. Shared Infrastructure Adapter を利用する QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS Config は [qvs_allowedSourceIps.yaml](./qvsconfig/qvs_allowedSourceIps.yaml) を利用してください。以下にデフォルトとの差分を示します。

    ```diff
    params:
      - name: appName
        type: string
      - name: azureTenantId
        type: string
      - name: azureSubscriptionId
        type: string
      - name: azureResourceGroupName
        type: string
      - name: azureDnsZoneResourceGroupName
        type: string
      - name: dnsZoneName
        type: string
      - name: keyVaultAccessAllowedObjectIds
        type: array
    + - name: applicationGatewayNsgAllowedSourceIps
    +   type: array

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.20.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure
        params:
          appName: $(params.appName)
          azureTenantId: $(params.azureTenantId)
          azureSubscriptionId: $(params.azureSubscriptionId)
          azureResourceGroupName: $(params.azureResourceGroupName)
          azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
          dnsZoneName: $(params.dnsZoneName)
          keyVaultAccessAllowedObjectIds: ["$(params.keyVaultAccessAllowedObjectIds[*])"]
    +     applicationGatewayNsgAllowedSourceIps: ["$(params.applicationGatewayNsgAllowedSourceIps[*])"]
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

3. QVS の画面から Deployment Config にパラメータを追加してください。

    以下の例の通り、複数のIPアドレスを設定する場合、カンマ区切りで引数を指定します。
    特定のIPアドレス範囲を設定する場合、CIDR表記で指定できます。

    ```yaml
    applicationGatewayNsgAllowedSourceIps: 192.168.0.1,172.16.0.0/12
    ```

### 複数種類のアプリケーションをデプロイしたい

同じ共有リソースに対して、API Backend Adapter を利用する複数の AssemblyLine を作成して複数種類のアプリケーションをデプロイできますが、全ての Optional なパラメータでデフォルト値を使用していた場合、2つめ以降の API Backend Adapter によって新規作成される一部のリソースが、同じ名前を持つ既存のリソースと競合してデプロイに失敗します。

このため、すでに API Backend Adapter でデフォルト値を使用してアプリケーションをデプロイ済みの状態で、さらに追加で別のアプリケーションをデプロイする場合は、新規作成されるリソースが既存のリソースと競合しないように、一部の Optional なパラメータではデフォルト値とは異なる値を明示的に設定する必要があります。

1. 以下のパラメータでは、複数の AssemblyLine で同じデフォルト値を共通的に使用できません。

    すでに1つの AssemblyLine でデフォルト値が使われている場合、2つめ以降の AssemblyLine ではデフォルト値とは異なる値を設定してください。

    - `mysqlCreateUserName`
    - `azureKeyVaultDbUserSecretName`
    - `azureKeyVaultDbPasswordSecretName`

2. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS Config は [qvs_another.yaml](./qvsconfig/qvs_another.yaml) を利用してください。以下にデフォルトとの差分を示します。

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
      - name: azureDnsARecordName
        type: string
      - name: azureStaticIpAddress
        type: string
      - name: mysqlCreateDbName
        type: string
      - name: azureKeyVaultKeyContainerName
        type: string
      - name: clusterIssuerName
        type: string
      - name: k8sNamespace
        type: string
      - name: imageName
        type: string
      - name: port
        type: string
      - name: dbHost
        type: string
      - name: redisHost
        type: string
      - name: redisPasswordSecretName
        type: string
      - name: host
        type: string
    + - name: mysqlCreateUserName
    +   type: string
    + - name: azureKeyVaultDbUserSecretName
    +   type: string
    + - name: azureKeyVaultDbPasswordSecretName
    +   type: string

    modules:
      - name: github.com/qmonus/official-cloud-native-adapters
        revision: v0.20.0

    designPatterns:
      - pattern: qmonus.net/adapter/official/adapters/azure/container/kubernetes/apiBackend
        params:
          appName: $(params.appName)
          azureSubscriptionId: $(params.azureSubscriptionId)
          azureResourceGroupName: $(params.azureResourceGroupName)
          azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
          azureDnsZoneName: $(params.azureDnsZoneName)
          azureDnsARecordName: $(params.azureDnsARecordName)
          azureStaticIpAddress: $(params.azureStaticIpAddress)
          mysqlCreateDbName: $(params.mysqlCreateDbName)
          azureKeyVaultKeyContainerName: $(params.azureKeyVaultKeyContainerName)
          clusterIssuerName: $(params.clusterIssuerName)
          k8sNamespace: $(params.k8sNamespace)
          imageName: $(params.imageName)
          port: $(params.port)
          dbHost: $(params.dbHost)
          redisHost: $(params.redisHost)
          redisPasswordSecretName: $(params.redisPasswordSecretName)
          host: $(params.host)
    +     mysqlCreateUserName: $(params.mysqlCreateUserName)
    +     azureKeyVaultDbUserSecretName: $(params.azureKeyVaultDbUserSecretName)
    +     azureKeyVaultDbPasswordSecretName: $(params.azureKeyVaultDbPasswordSecretName)
    ```

3. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

4. QVS の画面から Deployment Config にパラメータを追加してください。

    以下の例を参考にしてください。

    ```yaml
    mysqlCreateUserName: dbuser2
    azureKeyVaultDbUserSecretName: dbuser2
    azureKeyVaultDbPasswordSecretName: dbpassword2
    ```

そのほか指定可能なパラメータについては [API Backend Adapter](../../../../../adapters/azure/container/kubernetes/apiBackend/README.md)を参照してください。
