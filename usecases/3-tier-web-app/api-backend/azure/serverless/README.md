# API Backend Adapter の使い方

[API Backend Adapter](../../../../../adapters/azure/serverless/webApp/apiBackend/README.md) は、 [Shared Infrastructure Adapter](../../../../../adapters/azure/serverless/webApp/apiBackend/sharedInfrastructure/README.md) によってデプロイされた共有リソースと組み合わせて利用することで、Azure App Service を利用して API バックエンドアプリケーションを迅速にデプロイすることができます。
このドキュメントではお手持ちのアプリケーションを利用して、Azure 上に API バックエンドアプリケーションをデプロイする方法を記載しています。またユースケースに応じた設定変更について記載しています。

本ドキュメントはチュートリアル実施済みのユーザを対象としています。必要に応じて適宜[チュートリアル](https://docs.valuestream.qmonus.net/tutorials/)を参照してください。

## 事前準備

Adapter を利用して API バックエンドアプリケーションをデプロイするにあたり、以下の項目をご準備ください。

1. サービスプリンシパル の作成

   API Backend Adapter を利用して Web アプリケーションをデプロイする際、Azure App Service を利用するための権限が付与されたサービスプリンシパル を作成する必要があります。
   「[Azure 公式ドキュメントの作成手順](https://learn.microsoft.com/ja-jp/azure/active-directory/develop/howto-create-service-principal-portal) 」と「[API Backend Adapter のドキュメント](../../../../../adapters/azure/serverless/webApp/apiBackend/main.cue)」 を参考にして、必要な権限を付与したサービスプリンシパルを作成するか、以下に示している CLI での作成例を参考にしてください。

   Bash 環境で Azure CLI を利用してサービスプリンシパルを作成する場合の手順を示します。作成するサービスプリンシパルの権限は以下になります。

   - スコープ: サブスクリプション
   - ロール: 共同作成者

   Azure CLI が必要なため、[Azure Cloud Shell を利用する](https://learn.microsoft.com/ja-jp/azure/cloud-shell/quickstart?tabs=azurecli)、もしくは[Azure CLI をローカル端末にインストール](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli)して手順を実施してください。

   1. Azure テナントにサインインします

      ※Azure Cloudshell の場合は不要です。
      [Azure CLI を使用してサインインする](https://learn.microsoft.com/ja-jp/cli/azure/authenticate-azure-cli#authentication-methods) に基づき認証を行います。詳細は公式ドキュメントをご参照ください。

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

   1. 共同作成者ロールのサービスプリンシパルをサブスクリプションスコープで作ります

      `<YOUR_SERVICE_PRICIPAL_NAME>` は自身が登録したいサービスプリンシパル名に変更してください

      ```bash
      az ad sp create-for-rbac -n <YOUR_SERVICE_PRICIPAL_NAME> --role Contributor --scopes /subscriptions/${SUBSCID} /subscriptions/${SUBSCID}
      ```

      このとき、必ず表示された `appId`, `password`, `tenant` フィールドの値を別途保存してください。Environment リソースの作成時に利用します。

      `appId`: アプリケーションID
      `password`: サービスプリンシパルのシークレットキー
      `tenant`: テナントID

      もし保存し忘れてしまった場合は同じコマンドを再実行することで password が再生成されます。

   1. サービスプリンシパルが作成されたことを確認します

      ```bash
      az ad sp list --display-name <YOUR_SERVICE_PRICIPAL_NAME>
      ```

1. 共有リソースの作成

   API Backend Adapter を利用するには事前に必要なリソースがあります。

   - Azure DNS Zone（すでに作成済みの場合はスキップします）
   - [Shared Infrastructure Adapter](../../../../../adapters/azure/serverless/webApp/apiBackend/sharedInfrastructure/README.md) で作成されるリソース
     - リポジトリにデフォルト設定で利用できる Shared Infrastructure Adapter の QVS Config である [sharedInfrastructure.yaml](./qvsconfig/sharedInfrastructure.yaml) を配置しているので適宜利用してください。

## Value Stream によるリソースデプロイ

1. QVS Config の登録

   QVS Config をアプリケーションのリポジトリに登録してください。リポジトリに最小パラメータで利用できる [qvs.yaml](./qvsconfig/qvs.yaml) と、全パラメータを設定する [full_params_qvs.yaml](./qvsconfig/full_params_qvs.yaml) を配置しているので適宜利用してください。
   ユースケースに応じた設定変更は [こちら](#ユースケースに応じた設定変更) をご参照ください。

   以下に最小パラメータの QVS Config を示します。

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
       - name: containerRegistryName
         type: string
       - name: dnsZoneName
         type: string
       - name: dbHost
         type: string
       - name: redisHost
         type: string
       - name: azureKeyVaultName
         type: string
       - name: imageFullNameTag
         type: string
     modules:
       - name: github.com/qmonus/official-cloud-native-adapters
         revision: v0.21.0
     designPatterns:
       - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
         params:
           appName: $(params.appName)
           azureResourceGroupName: $(params.azureResourceGroupName)
           azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
           azureSubscriptionId: $(params.azureSubscriptionId)
           containerRegistryName: $(params.containerRegistryName)
           dnsZoneName: $(params.dnsZoneName)
           dbHost: $(params.dbHost)
           redisHost: $(params.redisHost)
           azureKeyVaultName: $(params.azureKeyVaultName)
           imageFullNameTag: $(params.imageFullNameTag)
   ```

1. Value Stream リソースの作成

   Repository、Application、Environment、Deployment などの QVS リソースを作成して登録してください。
   Environment リソース作成時、Azure の Provisioning Targetでは `Public` を選択してください。

1. Pipeline/Tasks の生成

   Qmonus Values Stream の Assemblyline のページにある `COMPILE AND APPLY PIPELINE/TASK` 機能を利用して Pipeline/Tasks を生成してください。

1. AssemblyLine の作成と登録、および実行

   AssemblyLine を作成して QVS に登録し、実行を行ってください。
   例として [assemblyline.yaml](./assemblyline.yaml) ファイルを配置していますので、必要に応じて参照してください。
   ファイル中のアプリケーション名や Deployment などを指定する <YOUR_XXXX> のパラメータは、自身の環境に合わせて適宜置き換えることができます。

   以下にAssemblyLine実行時に必要な Deployment Config の例を示します。
   それぞれのパラメータに関する説明については [API Backend Adapter](../../../../../adapters/azure/serverless/webApp/apiBackend/README.md) をご参照ください。

   ```
      azureDnsZoneResourceGroupName: <YOUR_DNS_ZONE_RESOURCE_GROUP_NAME>
      azureKeyVaultName: <YOUR_KEYVAULT_NAME>
      containerRegistryName: <YOUR_CONTAINER_REGISTRY_NAME>
      dbHost: <YOUR_DATABESE_HOST>
      dnsZoneName: <YOUR_DNS_ZONE_NAME>
      imageRegistryPath: <YOUR_IMAGE_REGISTRY_PATH>
      redisHost: <YOUR_REDIS_HOST>
   ```

1. 接続用 URL の確認

   AssemblyLine の実行に成功すると、AssemblyLine Results にデプロイされた API バックエンドへの接続 URL が出力されます。

## ユースケースに応じた設定変更

デプロイするアプリケーションを公開する際に利用できる Optional なパラメータがあります。ユースケースに応じて利用してください。

### 接続 URL を変更したい

デフォルトで設定される API バックエンドへの接続 URL は、 `api` のサブドメインを持ちます。任意のサブドメイン名を指定をすることでカスタムした接続 URL で API バックエンドにアクセスできるようになります。

1. QVS config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS config は [custom_domain.yaml](./qvsconfig/custom_domain.yaml) を利用してください。以下に最小パラメータのQVS Configとの差分を示します。

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
       - name: containerRegistryName
         type: string
       - name: dnsZoneName
         type: string
       - name: dbHost
         type: string
       - name: redisHost
         type: string
       - name: azureKeyVaultName
         type: string
       - name: imageFullNameTag
         type: string
   +   - name: subdomainName
   +     type: string
     modules:
       - name: github.com/qmonus/official-cloud-native-adapters
         revision: v0.21.0
     designPatterns:
       - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
         params:
           appName: $(params.appName)
           azureResourceGroupName: $(params.azureResourceGroupName)
           azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
           azureSubscriptionId: $(params.azureSubscriptionId)
           containerRegistryName: $(params.containerRegistryName)
           dnsZoneName: $(params.dnsZoneName)
           dbHost: $(params.dbHost)
           redisHost: $(params.redisHost)
           azureKeyVaultName: $(params.azureKeyVaultName)
           imageFullNameTag: $(params.imageFullNameTag)
   +       subDomainName: $(params.subdomainName)
   ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルを実施してください。

3. QVS の画面から Deployment Config に以下のパラメータを追加します。例として `my-app`を指定しています。

   ```yaml
   subDomainName: my-app
   ```

4. AssemblyLine を実行します。

   実行が成功すると Azure App Service で API バックエンド が作成され、公開される URL は `my-app` のサブドメインを持つようになります。
   Assemblyline Results に表示されている `customeDomain` を確認し、アクセスできることを確認してください。

### アプリケーションの引数を設定したい

デプロイするアプリケーションに任意の引数を設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS config は [qvs_args.yaml](./qvsconfig/qvs_args.yaml) を利用してください。以下に最小パラメータのQVS Configとの差分を示します。

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
        - name: containerRegistryName
          type: string
        - name: dbHost
          type: string
        - name: redisHost
          type: string
        - name: azureKeyVaultName
          type: string
        - name: imageFullNameTag
          type: string
   +    - name: args
   +      type: array
      modules:
        - name: github.com/qmonus/official-cloud-native-adapters
          revision: v0.21.0
      designPatterns:
        - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
          params:
            appName: $(params.appName)
            azureResourceGroupName: $(params.azureResourceGroupName)
            azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
            azureSubscriptionId: $(params.azureSubscriptionId)
            containerRegistryName: $(params.containerRegistryName)
            dbHost: $(params.dbHost)
            redisHost: $(params.redisHost)
            azureKeyVaultName: $(params.azureKeyVaultName)
            imageFullNameTag: $(params.imageFullNameTag)
   +        args: ["$(params.args[*])"]
   ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルを実施してください。

3. QVS の画面から Deployment Config にパラメータを追加してください。
   以下の例の通り、複数の引数を設定する場合、カンマ区切りで引数を指定します。

   ```yaml
   args: "--foo,--bar"
   ```

### アプリケーションの環境変数を設定したい

デプロイするアプリケーションに任意の環境変数を設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS config は [qvs_env.yaml](./qvsconfig/qvs_env.yaml) を利用してください。以下に最小パラメータのQVS Configとの差分を示します。
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
        - name: containerRegistryName
          type: string
        - name: dbHost
          type: string
        - name: redisHost
          type: string
        - name: azureKeyVaultName
          type: string
        - name: imageFullNameTag
          type: string
   +    - name: env1
   +      type: string
   +    - name: env2
   +      type: string
      modules:
        - name: github.com/qmonus/official-cloud-native-adapters
          revision: v0.21.0
      designPatterns:
        - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
          params:
            appName: $(params.appName)
            azureResourceGroupName: $(params.azureResourceGroupName)
            azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
            azureSubscriptionId: $(params.azureSubscriptionId)
            containerRegistryName: $(params.containerRegistryName)
            dbHost: $(params.dbHost)
            redisHost: $(params.redisHost)
            azureKeyVaultName: $(params.azureKeyVaultName)
            imageFullNameTag: $(params.imageFullNameTag)
   +        environmentVariables:
   +          ENV1: $(params.env1)
   +          ENV2: $(params.env2)
   ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルを実施してください。

3. QVS の画面から Deployment Config にパラメータを追加します。
   以下の例を参考にしてください。

   ```yaml
   env1: hoge
   env2: fuga
   ```

### アプリケーションのシークレットを設定したい

デプロイするアプリケーションに任意のシークレットを設定することができます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS config は [qvs_secret.yaml](./qvsconfig/qvs_secret.yaml) を利用してください。以下に最小パラメータのQVS Configとの差分を示します。
   [qvs_secret.yaml](./qvsconfig/qvs_secret.yaml) のSECRET1, SECRET2部分は、設定したい環境変数に置き換えてご利用ください。

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
       - name: containerRegistryName
         type: string
       - name: dbHost
         type: string
       - name: redisHost
         type: string
       - name: azureKeyVaultName
         type: string
       - name: imageFullNameTag
         type: string
   +   - name: secret1
   +     type: secret
   +   - name: secret2
   +     type: secret
     modules:
       - name: github.com/qmonus/official-cloud-native-adapters
         revision: v0.21.0
     designPatterns:
       - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
         params:
           appName: $(params.appName)
           azureResourceGroupName: $(params.azureResourceGroupName)
           azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
           azureSubscriptionId: $(params.azureSubscriptionId)
           containerRegistryName: $(params.containerRegistryName)
           dbHost: $(params.dbHost)
           redisHost: $(params.redisHost)
           azureKeyVaultName: $(params.azureKeyVaultName)
           imageFullNameTag: $(params.imageFullNameTag)
   +       secrets:
   +         SECRET1: $(params.secret1)
   +         SECRET2: $(params.secret2)
   ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルを実施してください。

3. secret1, secret2のキーをDeployment Secret画面から設定してください。Secretの登録方法については [Secretの登録](https://docs.valuestream.qmonus.net/guide/secrets.html)をご参照ください。

### アプリケーションの公開範囲を制限したい

デプロイするアプリケーションにアクセスできるソースIPアドレスを制限できます。制限しない場合は、インターネットの全てのIPアドレスからのアクセスが許可されます。

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS Config は [qvs_allowedSourceIps.yaml](./qvsconfig/qvs_allowedSourceIps.yaml) を利用してください。以下に最小パラメータのQVS Configとの差分を示します。

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
     - name: containerRegistryName
       type: string
     - name: dbHost
       type: string
     - name: redisHost
       type: string
     - name: azureKeyVaultName
       type: string
     - name: imageFullNameTag
       type: string
   + - name: appServiceAllowedSourceIps
   +   type: array

   modules:
     - name: github.com/qmonus/official-cloud-native-adapters
       revision: v0.19.0

   designPatterns:
     - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
       params:
         appName: $(params.appName)
         azureResourceGroupName: $(params.azureResourceGroupName)
         azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
         azureSubscriptionId: $(params.azureSubscriptionId)
         containerRegistryName: $(params.containerRegistryName)
         dbHost: $(params.dbHost)
         redisHost: $(params.redisHost)
         azureKeyVaultName: $(params.azureKeyVaultName)
         imageFullNameTag: $(params.imageFullNameTag)
   +     appServiceAllowedSourceIps: ["$(params.appServiceAllowedSourceIps[*])"]
   ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

3. QVS の画面から Deployment Config にパラメータを追加してください。

   以下の例の通り、複数のIPアドレスを設定する場合、カンマ区切りで引数を指定します。
   IPアドレスはCIDR表記で指定してください。CIDR表記の末尾が `/32` のIPアドレスを設定する場合も、`/32` まで省略せずに記述してください。

   ```yaml
   appServiceAllowedSourceIps: 192.168.0.1/32,172.16.0.0/12
   ```

### 複数種類のアプリケーションをデプロイしたい

同じ共有リソースに対して、API Backend Adapter を利用する複数の AssemblyLine を作成して複数種類のアプリケーションをデプロイできますが、全ての Optional なパラメータでデフォルト値を使用していた場合、2つめ以降の API Backend Adapter によって新規作成される一部のリソースが、同じ名前を持つ既存のリソースと競合してデプロイに失敗します。

このため、すでに API Backend Adapter でデフォルト値を使用してアプリケーションをデプロイ済みの状態で、さらに追加で別のアプリケーションをデプロイする場合は、新規作成されるリソースが既存のリソースと競合しないように、一部の Optional なパラメータではデフォルト値とは異なる値を明示的に設定する必要があります。

1. 以下のパラメータでは、複数の AssemblyLine で同じデフォルト値を共通的に使用できません。

   すでに1つの AssemblyLine でデフォルト値が使われている場合、2つめ以降の AssemblyLine ではデフォルト値とは異なる値を設定してください。

    - `subDomainName`

2. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

   QVS Config は [qvs_another.yaml](./qvsconfig/qvs_another.yaml) を利用してください。以下に最小パラメータのQVS Configとの差分を示します。

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
     - name: containerRegistryName
       type: string
     - name: dbHost
       type: string
     - name: redisHost
       type: string
     - name: azureKeyVaultName
       type: string
     - name: imageFullNameTag
       type: string
   + - name: subDomainName
   +   type: string

   modules:
     - name: github.com/qmonus/official-cloud-native-adapters
       revision: v0.19.0

   designPatterns:
     - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
       params:
         appName: $(params.appName)
         azureResourceGroupName: $(params.azureResourceGroupName)
         azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
         azureSubscriptionId: $(params.azureSubscriptionId)
         containerRegistryName: $(params.containerRegistryName)
         dbHost: $(params.dbHost)
         redisHost: $(params.redisHost)
         azureKeyVaultName: $(params.azureKeyVaultName)
         imageFullNameTag: $(params.imageFullNameTag)
   +     subDomainName: $(params.subDomainName)
   ```

3. コミット後、Pipeline および Task の更新のため、再度 Pipeline/Task のコンパイルと登録を実施してください。

4. QVS の画面から Deployment Config にパラメータを追加してください。

   以下の例を参考にしてください。

   ```yaml
   subDomainName: api2
   ```

### アプリケーションのログを取得したい

事前に [Shared Infrastructure Adapter](../../../../../adapters/azure/serverless/webApp/apiBackend/sharedInfrastructure/README.md) でデプロイしたLog Analytics Workspace にデプロイしたアプリケーションの stdout および stderr の出力を転送しログの収集(※)を行うことができます。[ログの設定](../../../api-backend/azure/container/log/README.md) についてもユースケースごとに記載しているため、適宜ご参照ください。
(共有リソースでログ機能を無効化している場合はログの収集ができません。)

1. QVS Config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

  QVS config は [qvs_collect_log.yaml](./qvsconfig/qvs_collect_log.yaml) を利用してください。以下に最小パラメータのQVS Configとの差分を示します。

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
       - name: containerRegistryName
         type: string
       - name: dbHost
         type: string
       - name: redisHost
         type: string
       - name: azureKeyVaultName
         type: string
       - name: imageFullNameTag
         type: string
  +    - name: enableContainerLog
  +      type: string
  +    - name: logAnalyticsWorkspaceId
  +      type: string
     modules:
       - name: github.com/qmonus/official-cloud-native-adapters
         revision: v0.21.0
     designPatterns:
       - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend
         params:
         appName: $(params.appName)
         azureResourceGroupName: $(params.azureResourceGroupName)
         azureDnsZoneResourceGroupName: $(params.azureDnsZoneResourceGroupName)
         azureSubscriptionId: $(params.azureSubscriptionId)
         containerRegistryName: $(params.containerRegistryName)
         dbHost: $(params.dbHost)
         redisHost: $(params.redisHost)
         azureKeyVaultName: $(params.azureKeyVaultName)
         imageFullNameTag: $(params.imageFullNameTag)
  +      enableContainerLog: $(params.enableContainerLog)
  +      logAnalyticsWorkspaceId: $(params.logAnalyticsWorkspaceId)
  ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルを実施してください。

3. QVS の画面から Deployment Config に以下のパラメータを追加します。

   Shared Infrastructure で共有リソースをデプロイした際 `get-log-analytics-workspace-info` タスクの結果として、 Pipeline Results にデプロイした Log Analytics Workspace の Workspace ID が出力されます。
   AssemblyLine Results として出力するように設定し AssemblyLine Resultsから参照するか、デプロイ時のVSのログの出力を参照してDeployment Configに入力してください。

   ```yaml
   logAnalyticsWorkspaceId: /subscriptions/xxxxx-yyyyyyyyy-zzzzz/resourceGroups/sample-rg/providers/Microsoft.OperationalInsights/workspaces/sample-workspace
   ```

そのほか指定可能なパラメータについては [API Backend Adapter](../../../../../adapters/azure/serverless/webApp/apiBackend/main.cue)をご参照ください。
