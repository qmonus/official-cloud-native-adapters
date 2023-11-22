# ログ機能 の使い方

API Backend Adapter をデプロイする際、[Shared Infrastructure Adapter](../../../../../../adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure/README.md) によってデプロイされた共有リソースでログ機能を有効にすることにより、[Log Analytics Workspace](https://learn.microsoft.com/ja-jp/azure/azure-monitor/logs/log-analytics-workspace-overview) の作成と、[ログ収集エージェントをAKSにインストール](https://learn.microsoft.com/ja-jp/azure/azure-monitor/containers/container-insights-enable-aks?tabs=azure-cli) することができ、AKSにデプロイされたBackendアプリケーションのログを取得することができます。

このドキュメントではお手持ちのアプリケーションを AKS にデプロイする際に、ログを取得するための方法を記載しています。またユースケースに応じた設定変更についても記載しています。

本ドキュメントはチュートリアル実施済みのユーザを対象としています。必要に応じて適宜[チュートリアル](https://docs.valuestream.qmonus.net/tutorials/)を参照してください。

## 事前準備

Adapter を利用してアプリケーションをデプロイするにあたり、以下の項目をご準備ください。

1. サービスプリンシパル の作成  
    Frontend Adapter を利用してWebアプリケーションをデプロイする際、Azure Static Web Apps を利用するための権限が付与されたサービスプリンシパル を作成する必要があります。
    「[ポータルで Azure AD アプリとサービス プリンシパルを作成する](https://learn.microsoft.com/ja-jp/azure/active-directory/develop/howto-create-service-principal-portal) 」と [Shared Infrastructure Adapter](../../../../../../adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure/README.md) を参考にして必要な権限を付与したサービスプリンシパルを作成するか、以下に示している Azure CLI での作成例を参考にしてください。

    Bash 環境でAzure CLIを利用してサービスプリンシパルを作成する場合の手順を示します。作成するサービスプリンシパルの権限は以下になります。

      - スコープ: サブスクリプション
      - ロール1: 共同作成者
      - ロール2: ユーザーアクセス管理者

    Azure CLI が必要なため「[Azure Cloud Shellを利用する](https://learn.microsoft.com/ja-jp/azure/cloud-shell/quickstart?tabs=azurecli)」、もしくは「[Azure CLIをローカル端末にインストール](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli)」を実施してから手順を実施してください。

    1. Azureテナントにサインインします  

        ※Azure Cloudshell の場合は不要です。  
        [Azure CLI を使用してサインインする](https://learn.microsoft.com/ja-jp/cli/azure/authenticate-azure-cli#authentication-methods) に基づき認証を行います。詳細は公式ドキュメントをご参照ください。

        ```bash
        az login
        ```

    1. サブスクリプションIDを取得します  
        サービスプリンシパルを作成するサブスクリプションと、権限のスコープ指定のためにサブスクリプションIDを取得し表示します。

        ```bash    
        SUBSCID=$(az account show --query id --output tsv)
        echo ${SUBSCID}
        ```

        このとき、必ず表示された値を別途保存してください。Value Stream の Environmentリソースの作成時に利用します。
    
    1. サービスプリンシパルを作成します。
        `<YOUR_SERVICE_PRICIPAL_NAME>` は自身が登録したいサービスプリンシパル名に変更してください    
        
        ```bash
        SERVICE_PRINCIPAL=$(az ad sp create-for-rbac -n <YOUR_SERVICEPRINCIPAL_NAME> --role Contributor --scopes /subscriptions/${SUBSCID} /subscriptions/${SUBSCID})
        SERVICE_PRINCIPAL_ID=$(echo $SERVICE_PRINCIPAL | jq -r .appId)
        az role assignment create --assignee $SERVICE_PRINCIPAL_ID --role "User Access Administrator" --scope /subscriptions/${SUBSCID}
        echo $SERVICE_PRINCIPAL
        ```

        このとき以下の値が表示されます。Value Stream の Environmentリソースの作成時に利用するため必ず各フィールドの値を別途保存してください。

        - `appId`: アプリケーションID
        - `password`: サービスプリンシパルのシークレットキー
        - `tenant`: テナントID

        もし保存し忘れてしまった場合、上記コマンドをすべて再実行することで各フィールドの値を再取得することができます。

    1. サービスプリンシパルが作成され、正しい権限が付与されていることを確認します  

        ```bash        
        az role assignment list --assignee $SERVICE_PRINCIPAL_ID --query "[].roleDefinitionName"  --output tsv
        # e.g. output is following
        # User Access Administrator
        # Contributor
        ```

## Value Stream によるリソースデプロイ
1. QVS Config の登録
    QVS Config をアプリケーションのリポジトリに登録してください。リポジトリに最小パラメータで利用できる [qvs.yaml](./qvsconfig/qvs.yaml) と、ログに関する全パラメータ (対話型の保存期間、コミットメントレベル、リージョン、日次上限、アクセスモード) を設定する [full_params_qvs.yaml](./qvsconfig/full_params_qvs.yaml) を配置しているので適宜利用してください。  
    
    以下に最小パラメータの QVS Config を示します。

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
      - name: enableContainerLog
        type: string

    modules:
      - name: qmonus.net/adapter/official
        revision: v0.18.0

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
          enableContainerLog: $(params.enableContainerLog)
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

- ユースケース一覧
  - [ログは取得するが開発環境のためコストを抑えたい](#ログは取得するが開発環境のためコストを抑えたい)
  - [1日当たりログが出る量が決まっており、そのログを活用するために頻繁に分析を行うケース](#1日当たりログが出る量が決まっておりそのログを活用するために頻繁に分析を行うケース)
  - [ログを使用しない](#ログを使用しない)


### ログは取得するが開発環境のためコストを抑えたい

ログを取得しますが、コストを抑制した設定のユースケースを記載します。

例として、本ユースケースでマッチしているログ運用は以下があります
- ログの量が大量ではないが、不意に大きなログが出ることを想定して上限を設けたい
- 開発用のログを試験的に収集していて監視設計をしている最中
- ログ管理の重要度が低い環境で、ログの長期保持そのものが不要

ログの保持期間を無料枠に抑えつつ、ログ量による従量課金が容量予約によるコストメリットを下回らないログ運用方針として以下の設定を行います。


- 1日当たりのログ上限: 50GB
  - 1日当たりに収集するログの上限値を設定します。50GBを上限とします。
- 対話型による保持期間: 30日
  - 30日までであれば無料枠のため、無料枠での保持期間設定を行います。このパラメータはデフォルトで `30` のため設定不要です。

1. QVS config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS config は [suppress_cost_dev.yaml](./qvsconfig/suppress_cost_dev.yaml) を利用してください。以下に最小パラメータとの差分を示します。

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
      - name: enableContainerLog
        type: string
    + - name: dailyQuotaGb
    +   type: string

    modules:
      - name: qmonus.net/adapter/official
        revision: v0.18.0

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
          enableContainerLog: $(params.enableContainerLog)
    +     dailyQuotaGb: $(params.dailyQuotaGb)
    ```

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルと登録を実施してください。

3. Value Stream の画面から Deployment Config に以下のパラメータを追加します。

  - `dailyQuotaGb: "50"`: ログ収集の日時上限 50GB

    ```yaml
    dailyQuotaGb: "50"
    ```

4. AssemblyLineを実行します。  
    実行が成功するとワークスペースが作成されAKSにエージェントがデプロイされます。すでにデプロイ済みの場合は更新されます。


### 1日当たりログが出る量が決まっておりそのログを活用するために頻繁に分析を行うケース

本ユースケースは、本番で稼働してるアプリケーションなどでキャパシティプランニングが終わっており、1日当たりに出力されるログ量が定量的であるケースや  
管理者やログ全体へのアクセスを行うログ管理者がセキュリティ監視やユーザ行動分析、運用改善などのためにログ活用をしたい・しているユースケースを記載します。

例として、本ユースケースにマッチしているログ運用は以下があります。
- 1日当たり出力されるログが 400-500 GB程度。しばし超過する時もある
- 四半期のログを利用しており、90日間のログが必要

ログ量による課金が従量課金に対してコストメリットを下回らないコミットメントレベルとし、ログ分析を想定したログ運用方針として以下の設定を行います。

- 対話型による保持期間: 90日
  - インタラクティブにクエリを実行し分析を行うためには対話型でのログの保持が必要になります。[参考](https://learn.microsoft.com/ja-jp/azure/azure-monitor/logs/data-retention-archive?tabs=portal-1%2Cportal-2#how-retention-and-archiving-work)
- ログ容量のコミットメントレベル：500GB/day
  - コミットメントレベルとは事前にどのくらいのリソースを利用するかを予約し、従量課金に対してディスカウントを受けられる課金体系です。[参考](https://learn.microsoft.com/ja-jp/azure/azure-monitor/logs/cost-logs#commitment-tiers)
- アクセスモード：ワークスペース全体へのアクセス
  - アクセスモードにはワークスペースとリソースレベルがあります。ワークスペースにすることで明示的にワークスペースに対してのアクセスを与えます。[参考](https://learn.microsoft.com/ja-jp/azure/azure-monitor/logs/manage-access?tabs=portal#access-mode)


1. QVS config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS config は [practical_logs.yaml](./qvsconfig/practical_logs.yaml) を利用してください。以下に最小パラメータとの差分を示します。

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
      - name: enableContainerLog
        type: string
    + - name: retentionInDays
    +   type: string
    + - name: capacityReservationLevel
    +   type: string
    + - name: enableLogAccessUsingOnlyResourcePermissions
    +   type: string

    modules:
      - name: qmonus.net/adapter/official
        revision: v0.18.0

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
          enableContainerLog: $(params.enableContainerLog)
    +     retentionInDays: $(params.retentionInDays)
    +     capacityReservationLevel: $(params.capacityReservationLevel)
    +     enableLogAccessUsingOnlyResourcePermissions: $(params.enableLogAccessUsingOnlyResourcePermissions)
    ```


2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルと登録を実施してください。

3. Value Stream の画面から Deployment Config に以下のパラメータを追加します。  
   各パラメータについての設定内容は以下です。

    - `retentionInDays: "90"`: 対話型による保持期間は90日
    - `capacityReservationLevel: "500"`: 1日当たりのログ量は500GBで予約
    - `enableLogAccessUsingOnlyResourcePermissions: "false"`: アクセス許可があるワークスペース内のログへの横断的なアクセス

    ```yaml
    retentionInDays: "90"
    capacityReservationLevel: "500"
    enableLogAccessUsingOnlyResourcePermissions: "false"
    ```

4. AssemblyLineを実行します。  
    実行が成功するとワークスペースが作成、すでにデプロイ済みの場合は更新されます。


## ログを使用しない

本ユースケースは、一時的な開発環境として利用するためログを使用しないユースケースです。

1. QVS config にパラメータを追加し、アプリケーションのリポジトリにコミットします。

    QVS config は [qvs.yaml](./qvsconfig/qvs.yaml) を利用してください。最小パラメータとの差分はありません。

2. コミット後、Pipeline および Task の更新のため、再度 Pipelines/Tasks のコンパイルと登録を実施してください。

3. Value Stream の画面から Deployment Config に以下のパラメータを追加します。

    ```yaml
    enableContainerLog: "false"
    ```

4. AssemblyLineを実行します。  
    実行が成功するとワークスペースの作成と、ログエージェントがデプロイされていないAKSが作成されます。
    また、Shared Infrastructure Adapter でデプロイしているワークスペースが存在する場合は削除されます。
    間違って削除してしまったが復元したい場合、論理削除されているため 「[Azure Log Analytics ワークスペースの削除と復旧](https://learn.microsoft.com/ja-jp/azure/azure-monitor/logs/delete-workspace)」 を参考にAzure Portal の Log Analytics Workspace の画面から復元してください。

ユースケースを組み合わせて利用することもできます。そのほか指定可能なパラメータについては [Shared Infrastructure Adapter](../../../../../../adapters/azure/container/kubernetes/apiBackend/sharedInfrastructure/README.md) をご参照ください。