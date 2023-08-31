# BlueGreen Deploy Adapter
Qmonus Value Streamを用いて、アプリケーションをユーザーの実行環境にBlueGreenデプロイストラテジーを利用してデプロイするためのCloud Native Adapterです。

本Adapterは[Argo Rollouts](https://argo-rollouts.readthedocs.io/en/stable/)における[BlueGreen Deployment Strategy](https://argo-rollouts.readthedocs.io/en/stable/features/bluegreen/)を利用してKubernetesリソースをデプロイするInfrastructure Adapter と組み合わせて利用することを前提としています。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/deploy:bluegreen`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Constraints
* qvsConfigPathで指定しているQVS ConfigにArgo Rollouts を利用したデプロイ対象となるInfrastructure Adapterが指定されている必要があります。
* 新規アプリケーションのデプロイ後、通常はpreview(ユーザトラフィックは受け付けないが確認は可能)状態になり、その後切り替え処理(promote)を行うことでactive(ユーザトラフィックを受け付ける)状態へ遷移しますが、最初のデプロイ時のみ自動でactive状態まで遷移します。
* Argo Rollouts の利用を前提としているため、Kubernetes リソースをデプロイする先のクラスタにはArgo Rolloutsがインストールされている必要があります。
  
## Platform
General / Platform Free
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| repositoryKind | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab |
| useDebug | bool | no | false | trueを指定すると、AssemblyLine実行時にQmonus Value Streamが適用するApplication Manifestの内容を出力します。| true |
| resourcePriority | string | no | medium |　マニフェストをコンパイルするTekton Task に割り当てるリソース量を設定します。 medium もしくは high のいずれかを設定でき、それぞれの割り当て量は下記の通りです。<br>・ medium → cpu:1, memory: 512MiB <br> ・ high → cpu:1, memory: 1GiB | high |
| useSshKey  | bool | no | false | trueを指定するとリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。 | true |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding | 
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl  | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | | yes |
| pathToSource | string | no | "" | ソースディレクトリからの相対パス |  | no |
| qvsConfigPath | string | yes | - | QVS Config(旧称：Application Config)のパス | .valuestream/qvs.yaml | yes |
| appName | string | yes | - | QVSにおけるApplication名 | nginx | yes |
| qvsDeploymentName | string | yes | - | QVSにおけるDeployment名 | staging | yes |
| deployStateName | string | no | main | pulumi-stack名のSuffixとして使用される | | no |
| providerType | string | no | kubernetes | デプロイ先のプロバイダーを指定する。基本的にはデフォルト値のkubernetesを使用 | | no |
| kubeconfigSecretName | string | yes | - | QVSにおけるDeploymentの作成時に指定したkubeconfigを保管しているk8s Secret名 | | yes |
| k8sNamespace | string | yes | - | Kubernetesリソースをデプロイする対象のnamepsace | demo-app-dev | yes |
| previewCheckTimeoutSeconds | string | no | 300 | preview状態になるまで待機する時間| | no |
| activeCheckTimeoutSeconds | string | no | 300 | preview状態からactive状態への切り替えが正常に完了するまで待機する時間 | | no |


## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| deploy  | git-checkout(-ssh), compile-design-pattern(-ssh), deployment-worker  のTaskを順番に実行し、アプリケーションを指定の環境にデプロイします。 |
| release  | wait-for-preview, approval-wait-for-preview, promote, wait-for-active  のTaskを順番に実行し、deployパイプラインでデプロイしたアプリケーションのBlueGreenデプロイを行います。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | deploy | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。|
| git-checkout-ssh | deploy | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。|
| compile-design-pattern | deploy | git-checkout | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、Application Manifestを生成します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。|
| compile-design-pattern-ssh | deploy | git-checkout-ssh | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、Application Manifestを生成します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。|
| deployment-worker | deploy | compile-design-pattern or compile-design-pattern-ssh | コンパイルされたApplication Manifestを指定の環境にデプロイします。|
| preview-check-rollout-status | release | - | アプリケーションが preview状態になるまで待機します。|
| approval | release | preview-check-rollout-status | ユーザからのアプリケーション切り替えの可否についての入力を待機します。|
| promote-rollout | release | approval | preview状態のアプリケーションをactive状態へ切り替える処理を行います。|
| active-check-rollout-status | release | promote-rollout | アプリケーションのpreview状態からactive状態への切り替え処理が正常に完了するまで待機します。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:bluegreen
    pipelineParams:
      repositoryKind: gitlab
      resourcePriority: high
```

## Code
[deploy:bluegreen](../../pipeline/deploy/bluegreen.cue)
