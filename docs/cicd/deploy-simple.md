# Simple Deploy Adapter
Qmonus Value Streamを用いて、アプリケーションをユーザーの実行環境にデプロイするためのCloud Native Adapterです。

## Module
- Module: `qmonus.net/adapter/official`
- Version: `v0.3.0`
- Import path `qmonus.net/adapter/official/pipeline/deploy:simple`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Constraints
* 本Adapterを使用する際は、デプロイ対象となるInfrastructure AdapterがQVS Configでインポートされている必要があります。
  
## Platform
General / Platform Free
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| repositoryKind  | string | no | "" | ソースコードの管理に使用しているリポジトリの種類を指定してください。 (e.g. github, gitlab, bitbucket)|
| useDebug | bool | no | false | trueを指定すると、AssemblyLine実行時にQmonus Value Streamが適用するApplication Manifestの内容を出力します。|
| deployPhase  | string | no | "" | アプリケーションをデプロイする際のPhaseを指定します。選択できる値は app, setup, "" のいずれかです。|
| resourcePriority | string | no | medium |　マニフェストをコンパイルするTekton Task に割り当てるリソース量を設定します。 **medium** もしくは **high** のいずれかを設定でき、それぞれの割り当て量は下記の通りです。<br>・ medium → cpu:1, memory: 512MiB <br> ・ high → cpu:1, memory: 1GiB

### Parameters
| Parameter Name | Type | Required | Default | Description | Auto Binding |
| --- | --- | --- | --- | --- | --- |
| gitRepositoryUrl  | string | yes | - | GitリポジトリサービスのURL(プロトコルは含まない) | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | yes |
| pathToSource | string | no | "" | ソースディレクトリからの相対パス | no |
| appConfigPath | string | yes | - | QVS Config(旧称：Application Config)のパス | yes |
| appName | string | yes | - | QVSにおけるApplication名 | yes |
| qvsDeploymentName | string | yes | - | QVSにおけるDeployment名 | yes |
| deployStateName | string | no | main | pulumi-stack名のSuffixとして使用される | no |
| providerType | string | no | kubernetes | デプロイ先のプロバイダータイプ | no |
| kubeconfigSecretName | string | yes | - | kubeconfigを保管しているk8s Secret名 | yes |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| deploy  | git-checkout, compile-design-pattern, deployment-worker  のTaskを順番に実行し、アプリケーションを指定の環境にデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | deploy | - | 指定のリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。 |
| compile-design-pattern | deploy | git-checkout | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、アプリケーションマニフェストを生成します。|
| deployment-worker | deploy | compile-design-pattern | コンパイルされたアプリケーションマニフェストを指定の環境にデプロイします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:simple
    pipelineParams:
      repositoryKind: github
      resourcePriority: high
```

## Code
[deploy:simple](../../pipeline/deploy/simple.cue)
