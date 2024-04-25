# Shared Infrastructure Adapter

HTTPSで外部公開できるアプリケーションをAzure上にデプロイするために、必要なAzureリソース群をデプロイするCloud Native Adapterです。

以下のリソースを作成します。

* Azure Resource Group
    * 下記のリソースが所属するリソースグループを作成します。
* Azure Cache for Redis
    * Azureで固有のリソース名とする必要があるため、サフィックスとしてランダムな8文字を付与します。
    * 作成時に併せて、アクセスキーがKey Vaultに`redisaccesskey`という名前で格納されます。
* Azure Container Registry
    * Azureで固有のリソース名とする必要があるため、サフィックスとしてランダムな8文字を付与します。
* Azure Database for MySQL
    * Azureで固有のリソース名とする必要があるため、サフィックスとしてランダムな8文字を付与します。
    * 作成時に併せて、Adminユーザ:`admin_user`とパスワードがそれぞれ`dbadminuser`と`dbadminpassword`というシークレット名でKey Vaultに格納されます。
* Azure Key Vault
    * MySQLのパスワードやRedisのアクセスキーを格納します。
    * アクセスポリシーを使用して、Qmonus Value Streamに登録されたサービスプリンシパル、および任意のユーザからのシークレットへのアクセスを許可します。
    * 論理削除が有効であるため、同名のシークレットを再作成するには物理削除をAzure Portal等から行う必要があります。
* Azure Log Analytics Workspace
    * ログを格納する Log Analytics Workspace を作成します。
* Azure Network Security Group
    * App Service用のNSGを作成してサブネットに関連付けます。
    * セキュリティ規則は任意のポート・プロトコル・IPアドレスからのアクセスを許可します。
* Azure Virtual Network
    * App Service用のサブネットが所属するVirtual Networkを作成します。
* Azure Virtual Network Subnet
    * 以下のサブネットを/22のネットワークセグメントで作成します。
        * Azure App Serviceが所属するサブネット

![Architecture](images/image.png)

## Platform

Microsoft Azure

## Module

* Module: `qmonus.net/adapter/official`
* Import path `qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend/sharedInfrastructure`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites

* 事前にサービスプリンシパルを作成し、Qmonus Value Streamへ認証情報を登録する必要があります。以下の権限をサブスクリプション配下で付与してください。
    * 共同作成者
    * ユーザー アクセス管理者
* 事前にDNS ゾーンを作成する必要があります。Azure に DNSゾーンを作成し、各委譲元のDNSプロバイダで委譲設定を行ってください。
    
    ※DNS ゾーンを作成せず、お持ちの既存のAzure DNSゾーンを利用する場合は本手順は不要です。
    
    - Azure Portal で作成する
        - [クイック スタート:DNS ゾーンとレコードの作成](https://learn.microsoft.com/ja-jp/azure/dns/dns-getstarted-portal) およびそのほか公式ドキュメントをご参照ください。
    - Azure CLI を利用して作成する  
        DNSゾーンの作成および委譲設定を行う方法例を示します。
        
        - 前提条件
            - 委譲元のDNSゾーンがAzureであり、かつ委譲先のDNSゾーンもAzureである
            - Azure Cloud Shell でbashを利用している/ローカルのbash環境に Azure CLI がインストールされている [※参考：AzureCLIの概要](https://learn.microsoft.com/ja-jp/cli/azure/get-started-with-azure-cli)

        1. Azureテナントにサインインします  

            ※Azure Cloudshell の場合は不要です。  
            [Azure CLI を使用してサインインする](https://learn.microsoft.com/ja-jp/cli/azure/authenticate-azure-cli#authentication-methods) に基づき認証を行います。詳細は公式ドキュメントをご参照ください。

            ```bash
            az login
            ```
        
        1. DNSゾーンを作成するために必要な情報を変数に格納します
        任意の値に置き換えて、それぞれ格納してください
            - `CHILD_ZONE_NAME` : 作成する子ゾーン(委譲先ゾーン)の名前
            - `CHILD_RG`: 委譲先の子ゾーンを所属させる、もしくは所属しているリソースグループ
            - `PARENT_ZONE_NAME`: 既にある親ゾーン(委譲元ゾーン)の名前
            - `PARENT_RG` : 委譲元の親ゾーンが所属しているリソースグループ
            
            ```bash
            CHILD_ZONE_NAME="<YOUR_CHILD_ZONE_NAME>"   # e.g. myapp.example.com
            CHILD_RG="<YOUR_CHILD_RG>"   # e.g. "my-child-rg"
            PARENT_ZONE_NAME="<YOUR_PARENT_ZONE>"   # e.g. "example.com"
            PARENT_RG="<YOUR_PARENT_RG>"   # e.g. "my-parent-rg"
            CHILD_ZONE_NAME_WITHOUT_PARENT_ZONE=${CHILD_ZONE_NAME%.$PARENT_ZONE_NAME}   # remove parent zone domain. result is "myapp" in this case.
            ```
            
        1. リソースグループを作成します。
        ※すでに作成済みのリソースグループに所属させる場合はSkipで構いません。
        location には任意のロケーションを指定してください。
            
            ```bash
            az group create --name ${CHILD_RG} --location "Japan East"
            ```
            
        
        1. 委譲先の子ゾーンを作成する
            
            ```bash
            az network dns zone create --name ${CHILD_ZONE_NAME} --resource-group ${CHILD_RG}
            ```
            
        1.  子ゾーンのネームサーバーを確認します
            
            ```bash
            az network dns zone show --name ${CHILD_ZONE_NAME} --resource-group ${CHILD_RG} --query 'nameServers' -o tsv
            ```
            
        1. 子ゾーンのネームサーバーを委譲元の親ゾーンに設定します。
            
            ```bash
            nsservers=$(az network dns zone show --name ${CHILD_ZONE_NAME} --resource-group ${CHILD_RG} --query 'nameServers' -o tsv)
            for nsserver in ${nsservers[@]} ; do az network dns record-set ns add-record --resource-group ${PARENT_RG} --zone-name ${PARENT_ZONE_NAME} --record-set-name ${CHILD_ZONE_NAME_WITHOUT_PARENT_ZONE} --nsdname $nsserver; done;
            ```
            
        1. 正常に設定できたかを確認します。
            
            確認のためにTXTレコードを設定します。
            
            ```bash
            az network dns record-set txt add-record --record-set-name hello --value "world" --resource-group ${CHILD_RG} --zone-name ${CHILD_ZONE_NAME}
            ```
            
            以下のコマンドを実行し、answerとして ”world” が出力されていれば正しく設定されています。
            
            ```bash
            dig TXT +noall +ans hello.${CHILD_ZONE_NAME}
            ```
            
            確認後、不要なTXTレコードを削除します。
            
            ```bash
            az network dns record-set txt remove-record --record-set-name hello --value "world"  --resource-group ${CHILD_RG} --zone-name ${CHILD_ZONE_NAME}
            ```


### Constraints

* 作成するMySQLのAdminユーザアカウントのパスワードは、1文字以上の大小英数字記号を含む、16文字でランダムで生成されます。
* ゾーン分散などの冗長化は行いません。

## Infrastructure Parameters

| Parameter Name                 | Type   | Required | Default        | Description                                                                                                                                                                                                                                                | Example                                                                     | Auto Binding |
|--------------------------------|--------|----------|----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------|--------------|
| appName                        | string | yes      | -              | デプロイするアプリケーション名                                                                                                                                                                                                                                            | sample                                                                      | yes          |
| azureSubscriptionId            | string | yes      | -              | 事前に用意したAzureのサブスクリプション名                                                                                                                                                                                                                                    | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx                                        | yes          |
| azureTenantId                  | string | yes      | -              | 事前に用意したAzureのテナントID                                                                                                                                                                                                                                        | yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy                                        | yes          |
| azureResourceGroupName         | string | yes      | -              | 作成するリソースグループ名                                                                                                                                                                                                                                              | sample-resourcegroup                                                        | yes          |
| keyVaultAccessAllowedObjectIds | array  | yes      | -              | Key Vaultのシークレットにアクセスを許可するオブジェクトIDのリスト <br> 以下を参考に、アクセスを許可したいユーザプリンシパルまたはADアプリケーションに対応するオブジェクトIDを指定してください。 <br> https://learn.microsoft.com/ja-jp/partner-center/marketplace/find-tenant-object-id#find-user-object-id                                     | "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa,bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" | no           |
| mysqlSkuName                   | string | no       | B_Standard_B2s | MySQLのSKU名<br>以下を参考に、SKU名を指定してください。<br>https://learn.microsoft.com/ja-jp/azure/mysql/flexible-server/concepts-service-tiers-storage<br>また、指定するコンピューティング レベルに従ってプレフィックスをつける必要があります。<br>例：コンピューティング レベル`Burstable`の場合はB、`General Purpose`の場合はGPをプレフィックスとします。 | GP_Standard_D16ds_v4                                                        | no           |
| mysqlVersion                   | string | no       | "8.0.21"       | MySQLのバージョン<br>`5.7`,`8.0.21`のいずれかを指定します。                                                                                                                                                                                                                  | "5.7"                                                                       | no           |
| enableContainerLog             | string | no       | "true"           | ログ機能の有効/無効。`true`` にした場合、Log Analytics Workspace の作成が行われます。 | "true" | no |
| retentionInDays                | string | no | "30" | `enableContainerLog` が `"true"` の場合のみ設定できます。各ログのテーブルを対話型で保持する期間を設定します。最長で 730 (2年間) まで指定することができます | "30" | no |
| location                       | string | no | "Japaneast" | `enableContainerLog` が `"true"` の場合のみ設定できます。Log Analytics Workspace をデプロイするロケーションを設定します | Japaneast | no |
| capacityReservationLevel       | string | no | "100" | `enableContainerLog` が `"true"` の場合のみ設定できます。sku に `CapacityReservation` を設定した際、コミットメントレベルを指定します。詳細は[公式の「 Log Analytics ワークスペースの価格レベルを変更する」](https://learn.microsoft.com/ja-jp/azure/azure-monitor/logs/change-pricing-tier?tabs=azure-portal))を確認してください | "100" | no |
| dailyQuotaGb                   | string | no | "-1"  | `enableContainerLog` が `"true"` の場合のみ設定できます。Log Analytics Workspace に対する1日当たりのログの日次上限で単位はGBです。デフォルトは無制限になっています。 | "-1" | no |
| workspaceAccessMode | string | no | "resource" | `enableContainerLog` が `"true"` の場合のみ設定できます。Log Analytics Workspace へのアクセスモードを指定します。`resource` の場合、ユーザはアクセス許可のあるリソースのログを確認することが可能です。ワークスペース全体へのアクセスはできません。`workspace` の場合、ユーザがログにアクセスするためには、明示的にワークスペースへアクセス許可を付与される必要があります。| "resource" or "workspace"  | no |

## CI/CD Parameters

### Adapter Options

| Parameter Name | Type   | Required | Default | Description                                                                                                      | Example |
|----------------|--------|----------|---------|------------------------------------------------------------------------------------------------------------------|---------|
| repositoryKind | string | no       | ""      | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab  |
| useSshKey      | bool   | no       | false   | trueを指定するとリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。                                                               | true    |

### Parameters

| Parameter Name              | Type   | Required | Default | Description                                      | Example                                              | Auto Binding |
|-----------------------------|--------|----------|---------|--------------------------------------------------|------------------------------------------------------|--------------|
| gitCloneUrl                 | string | yes      | -       | GitリポジトリサービスのURL                                 | https://github.com/${organization}/${repository} | yes          |
| gitRevision                 | string | yes      | -       | Gitのリビジョン                                        |                                                      | no           |
| gitRepositoryDeleteExisting | bool   | no       | true    | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する |                                                      | no           |
| gitCheckoutSubDirectory     | string | no       | ""      | GitのCheckout作業をするパス名                             |                                                      | no           |
| gitTokenSecretName          | string | yes      | -       | Gitのアクセストークンを保管しているk8s Secret名                   |                                                      | yes          |
| pathToSource                | string | no       | ""      | ソースディレクトリからの相対パス                                 |                                                      | no           |
| qvsConfigPath               | string | yes      | -       | QVS Config(旧称：Application Config)のパス             | .valuestream/qvs.yaml                                | yes          |
| appName                     | string | yes      | -       | QVSにおけるApplication名                              | nginx                                                | yes          |
| qvsDeploymentName           | string | yes      | -       | QVSにおけるDeployment名                               | staging                                              | yes          |
| deployStateName             | string | no       | main    | pulumi-stack名のSuffixとして使用される                     |                                                      | no           |
| azureApplicationId          | string | yes      | -       | AzureのApplicationID                              |                                                      | yes          |
| azureTenantId               | string | yes      | -       | AzureのTenantID                                   |                                                      | yes          |
| azureSubscriptionId         | string | yes      | -       | AzureのSubscriptionID                             |                                                      | yes          |
| azureClientSecretName       | string | yes      | -       | AzureのClientSecretを保管しているSecret名                 |                                                      | yes          |

### Results Parameters

| Parameter Name | Pipeline | Type | Description | Example |
| --- | --- | --- | --- | --- |
| logAnalyticsWorkspaceId | deploy | string | Log Analytics Workspace のID | /subscriptions/xxxxx-yyyyyyyyy-zzzzz/resourceGroups/sample-rg/providers/Microsoft.OperationalInsights/workspaces/sample-workspace |
| LogAnworkspaceName | deploy | string | Log Analytics Workspace の名前 | sample-workspace |

## Application Resources

| Resource ID                            | Provider | Resource Name                | Description                                                                        |
|----------------------------------------|----------|------------------------------|------------------------------------------------------------------------------------|
| mysql                                  | Azure    | Azure Database for MySQL     | MySQLのフレキシブルサーバーを作成します。                                                            |
| mysqlNameSuffix                        | Random   | RandomString                 | Mysql Nameの末尾に追加するランダム文字列（8文字）を生成します。Global Uniqueの制約のために追加しています。                  |
| mysqlAdminPassword                     | Random   | RandomPassword               | 新規作成するMySQL Adminパスワードを16文字の英大数字で生成します。                                            |
| mysqlAdminUserSecret                   | Azure    | Azure Key Vault              | Key VaultにMySQL Adminユーザ名を格納したシークレットを作成します。                                        |
| mysqlAdminPasswordSecret               | Azure    | Azure Key Vault              | Key VaultにMySQL Adminパスワードを格納したシークレットを作成します。                                       |
| mysqlFirewallRule                      | Azure    | Azure Database for MySQL     | MySQL用のファイアウォールを設定します。                                                             |
| redis                                  | Azure    | Azure Cache for Redis        | redisインスタンスを作成します。                                                                 |
| redisFirewallRule                      | Azure    | Azure Cache for Redis        | redis用のファイアウォールを設定します。                                                             |
| redisNameSuffix                        | Random   | RandomString                 | Redis Nameの末尾に追加するランダム文字列（8文字）を生成します。Global Uniqueの制約のために追加しています。                  |
| redisPrimaryKeySecret                  | Azure    | Azure Key Vault              | Key VaultにMySQL Adminパスワードを格納したシークレットを作成します。                                       |
| virtualNetwork                         | Azure    | Azure Virtual Network        | 仮想ネットワークを作成します。                                                                    |
| virtualNetworkWebAppSubnet             | Azure    | Azure Virtual Network        | 仮想ネットワークにApp Service用のサブネットを作成します。                                                 |
| networkSecurityGroupWebApp             | Azure    | Azure Network Security Group | アプリケーションゲートウェイ用のサブネットに適用するネットワークセキュリティグループを作成します。                                  |
| registryNameSuffix                     | Random   | RandomString                 | Registry Nameの末尾に追加するランダム文字列（8文字）を生成します。Global Uniqueの制約のために追加しています。               |
| containerRegistry                      | Azure    | Azure Container Registry     | Container Registryを作成します。                                                          |
| vaultNameSuffix                        | Random   | RandomString                 | Vault Nameの末尾に追加するランダム文字列（8文字）を生成します。Global Uniqueの制約のために追加しています。                  |
| keyVault                               | Azure    | Azure Key Vault              | Key Vaultを作成します。                                                                   |
| resourceGroup                          | Azure    | Azure Resource Manager       | リソースグループを作成します。                                                                    |
| keyVaultAccessPolicyForQvs             | Azure    | Azure Key Vault              | Qmonus Value Streamに登録したサービスプリンシパルがKeyvaultに対して値の読み取り・書き込みを行うために必要なアクセスポリシーを生成します。 |
| keyVaultAccessPolicyForUser            | Azure    | Azure Key Vault              | 任意のオブジェクトIDがKeyvaultに対して値の読み取り・書き込みを行うために必要なアクセスポリシーを生成します。                        |
| logAnalyticsWorkspace                  | Azure    | Log Analytics Workspace      | ログを格納するワークスペースを作成します。 |

## Pipeline Resources

以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline

| Resource ID | Description                                                                                                            |
|-------------|------------------------------------------------------------------------------------------------------------------------|
| deploy      | git-checkout(-ssh), compile-adapter-into-pulumi-yaml(-ssh), deploy-by-pulumi-yaml のTaskを順番に実行し、アプリケーションを指定の環境にデプロイします。また、`enableContainerLog` が true の場合は get-log-analytics-workspace-info のTaskを実行し、作成された Log Analytics Workspace の情報をPipeline Resultsに格納します。 |

### Task

| Resource ID                          | Pipeline | runAfter                                                                 | Description                                                                                                                                                       |
|--------------------------------------|----------|--------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| git-checkout                         | deploy   | -                                                                        | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。                   |
| git-checkout-ssh                     | deploy   | -                                                                        | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。                 |
| compile-adapter-into-pulumi-yaml     | deploy   | git-checkout                                                             | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、PulumiYamlのプロジェクトファイルを生成します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。     |
| compile-adapter-into-pulumi-yaml-ssh | deploy   | git-checkout-ssh                                                         | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、PulumiYamlのプロジェクトファイルを生成します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。 |
| deploy-by-pulumi-yaml                | deploy   | compile-adapter-into-pulumi-yaml or compile-adapter-into-pulumi-yaml-ssh | コンパイルされたPulumiYamlのプロジェクトファイルを指定の環境にデプロイします。                                 
| get-log-analytics-workspace-info | get-info |  | deploy pipeline で作成された Log Analytics Workspace の情報として ワークスペースのIDである `logAnalyticsWorkspaceId` とワークスペース名である `logAnalyticsWorkspaceName` を Pipeline Resultsに格納します。出力した値はAssemblyLine Resultsとして出力することができます。|


## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/adapters/azure/serverless/webApp/apiBackend/sharedInfrastructure
    params:
      appName: $(params.appName)
      azureResourceGroupName: $(params.azureResourceGroupName)
      azureTenantId: $(params.azureTenantId)
      azureSubscriptionId: $(params.azureSubscriptionId)
      keyVaultAccessAllowedObjectIds: [ "$(params.keyVaultAccessAllowedObjectIds[*])" ]
      enableContainerLog: $(paramas.enableContainerLog)
```

## Code

[sharedInfrastructure](./main.cue)
