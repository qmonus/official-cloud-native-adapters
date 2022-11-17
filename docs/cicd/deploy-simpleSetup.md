# Simple Deploy Setup Adapter
Qmonus Value Streamを用いて、アプリケーションをユーザーの実行環境にデプロイするためのCloud Native Adapterです。
[Simple Deploy Adapter](./deploy-simple.md)に対して、Adapter Optionsで`deployPhase: "setup"`と設定したものと同一のCI/CD Adapterになります。

以下のように、Infrastructure Adapterで`resources.appSetup`と宣言されたリソースのみをデプロイ対象とします。

```cue
package sampleSetup

DesignPattern: {
[...]
  resources: appSetup: {
		configmap: _configmap
  }
[...]
}
```

例として[Usage](#usage)のように、明示的に`deployPhase` Adapter Optionsを設定せずに、本Adapterでアプリケーションの事前準備となるリソースをデプロイ後、[Simple Deploy App Adapter](./deploy-simpleDeploy.md)でアプリケーションをデプロイするような、段階的なCI/CDを可能にするPipeline/Taskを生成することが可能です。

## Module
- Module: `qmonus.net/adapter/official`
- Version: `v0.3.0`
- Import path `qmonus.net/adapter/official/pipeline/deploy:simpleSetup`

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
| deployStateName | string | no | setup | pulumi-stack名のSuffixとして使用される | no |
| providerType | string | no | kubernetes | デプロイ先のプロバイダータイプ | no |
| kubeconfigSecretName | string | yes | - | kubeconfigを保管しているk8s Secret名 | yes |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| setup  | git-checkout, compile-design-pattern, deployment-worker  のTaskを順番に実行し、アプリケーションを指定の環境にデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | deploy | - | 指定のリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。 |
| compile-design-pattern | deploy | git-checkout | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、アプリケーションマニフェストを生成します。|
| deployment-worker | deploy | compile-design-pattern | コンパイルされたアプリケーションマニフェストを指定の環境にデプロイします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:simpleSetup
    pipelineParams:
      repositoryKind: github
      resourcePriority: high
  - pattern: qmonus.net/adapter/official/pipeline/deploy:simpleApp # simpleAppをともに宣言することで、Qmonus Value Streamで段階的なデプロイを行うことができるPipeline/Taskを生成する
    pipelineParams:
      repositoryKind: github
      resourcePriority: high
```

## Code
[deploy:simpleSetup](../../pipeline/deploy/simpleSetup.cue)
