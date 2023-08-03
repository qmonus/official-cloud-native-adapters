# Simple Deploy by Pulumi Yaml Adapter
Qmonus Value Streamを用いて、アプリケーションをユーザーの実行環境にデプロイするためのCloud Native Adapterです。
[Simple Deploy Adapter](./deploy-simple.md)が主にKubernetes環境用に定義されたInfrastructure Adapterをサポートするのに対して、`simpleDeployByPulumiYaml`はKubernetesとパブリッククラウド環境用に定義されたInfrastructure Adapterを広くサポートします。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml`

## Level
Sample: サンプル実装

## Prerequisites / Constraints

### Constraints
* qvsConfigPathで指定しているQVS Configにデプロイ対象となるInfrastructure Adapterが指定されている必要があります。

## Platform
General / Platform Free

## Parameters

### Adapter Options
| Parameter Name | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| repositoryKind | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab |
| useDebug | bool | no | false | trueを指定すると、AssemblyLine実行時にQmonus Value Streamが適用するApplication Manifestの内容を出力します。 | true |
| deployPhase | string | no | "" | Qmonus Value Streamにおけるコンパイル・デプロイ単位を示すフェーズを指定します。選択できる値は app, "" のいずれかです。 | app |
| resourcePriority | string | no | medium | マニフェストをコンパイルするTekton Task に割り当てるリソース量を設定します。 medium もしくは high のいずれかを設定でき、それぞれの割り当て量は下記の通りです。<br>・ medium → cpu:1, memory: 512MiB <br> ・ high → cpu:1, memory: 1GiB | high |
| useSshKey | bool | no | false | trueを指定するとリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。 | true |
| importStackName | string | no | "" | deployment-workerでのデプロイで生成されたStackをimportしたい場合に、そのStack名を指定して下さい。 | <span>$</span>(params.appName)-<span>$</span>(params.qvsDeploymentName)-<span>$</span>(params.deployStateName) |
| useCred | object | no | - | サブプロパティでPulumiYamlでのデプロイに使用するCredentialを指定して下さい。 | - |
| useCred.kubernetes | bool | no | false | trueを指定するとKubernetesにリソースをデプロイする際に、Value Streamで設定されたCredentialを参照できるようになります 。 | true |
| useCred.gcp | bool | no | false | trueを指定するとGCPにリソースをデプロイする際に、Value Streamで設定されたCredentialを参照できるようになります。 | true |
| useCred.aws | bool | no | false | trueを指定するとAWSにリソースをデプロイする際に、Value Streamで設定されたCredentialを参照できるようになります。 | true |
| useCred.azure | bool | no | false | trueを指定するとAzureにリソースをデプロイする際に、Value Streamで設定されたCredentialを参照できるようになります。 | true |
| useBastionSshCred | bool | no | false | trueを指定すると、Value Streamで設定されたCredentialを参照し、外部公開されている踏み台サーバへポートフォワードを行い、踏み台サーバ経由でリソースをデプロイすることができます。 | true |
| pulumiCredentialName | string | no | qmonus-pulumi-secret | Pulumi Stack上の機密情報を暗号化するためのパスフレーズを格納したCredential名を指定してください。| custom-pulumi-credential |


**補足事項**
* `pulumiCredentialName`をデフォルトの値以外で使用する場合には、以下を参考にしてValue StreamのCredentialにて設定してください。
  * シークレット名は任意です。作成したシークレット名を、`pulumiCredentialName`としてPipelineParamsから指定します。[Usage](#usage)を参考にしてください。
  * キー名は、`passphrase`としてください。
 
### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision | string | yes | - | Gitのリビジョン | | no |
| gitRepositoryDeleteExisting | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているSecret名 | | yes |
| pathToSource | string | no | "" | ソースディレクトリからの相対パス | | no |
| qvsConfigPath | string | yes | - | QVS Config(旧称：Application Config)のパス | .valuestream/qvs.yaml | yes |
| appName | string | yes | - | QVSにおけるApplication名 | nginx | yes |
| qvsDeploymentName | string | yes | - | QVSにおけるDeployment名 | staging | yes |
| deployStateName | string | no | main | pulumi-stack名のSuffixとして使用される | | no |
| kubeconfigSecretName | string | no | - | QVSにおけるDeploymentの作成時に指定したkubeconfigを保管しているSecret名 | | yes |
| gcpServiceAccountSecretName | string | no | - | QVSにおけるDeploymentの作成時に指定したGCPサービスアカウントのjsonキーを保管しているSecret名 | | yes |
| awsCredentialName | string | no | - | QVSにおけるCredentialの作成時に指定したAWSのProfileを保管しているSecret名 | | no |
| azureApplicationId | string | no | - | AzureのApplicationID | | yes |
| azureTenantId | string | no | - | AzureのTenantID | | yes |
| azureSubscriptionId | string | no | - | AzureのSubscriptionID | | yes |
| azureClientSecretName | string | no | - | AzureのClientSecretを保管しているSecret名 | | yes |
| bastionSshHost | string | no | - | 踏み台サーバのホスト名またはIPアドレス | | no |
| bastionSshUserName | string | no | - | 踏み台サーバへ接続するためのユーザ名 | | no |
| bastionSshKeySecretName | string | no | - |  踏み台サーバの秘密鍵のシークレット名 | | yes |
| sshPortForwardingDestinationHost | string | no | - | 踏み台サーバ経由でアクセスするリソースのホスト名 | | no |
| sshPortForwardingDestinationPort | string | no | - | 踏み台サーバ経由でアクセスするリソースへの接続ポート | | no |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| deploy | git-checkout(-ssh), compile-adapter-into-pulumi-yaml(-ssh), deploy-by-pulumi-yaml のTaskを順番に実行し、アプリケーションを指定の環境にデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | deploy | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。 |
| git-checkout-ssh | deploy | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。 |
| compile-adapter-into-pulumi-yaml | deploy | git-checkout | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、PulumiYamlのプロジェクトファイルを生成します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。 |
| compile-adapter-into-pulumi-yaml-ssh | deploy | git-checkout-ssh | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、PulumiYamlのプロジェクトファイルを生成します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。 |
| deploy-by-pulumi-yaml | deploy | compile-adapter-into-pulumi-yaml or compile-adapter-into-pulumi-yaml-ssh | コンパイルされたPulumiYamlのプロジェクトファイルを指定の環境にデプロイします。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:simpleDeployByPulumiYaml
    pipelineParams:
      repositoryKind: gitlab
      resourcePriority: high
      useCred:
        kubernetes: false
        gcp: true
        aws: false
        azure: true
```

## Code
[deploy:simpleDeployByPulumiYaml](../../pipeline/deploy/simpleDeployByPulumiYaml.cue)
