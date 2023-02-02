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
- Import path `qmonus.net/adapter/official/pipeline/deploy:simpleSetup`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Constraints
* qvsConfigPathで指定しているQVS Configにデプロイ対象となるInfrastructure Adapterが指定されている必要があります。
  
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

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| setup  | git-checkout(-ssh), compile-design-pattern(-ssh), deployment-worker  のTaskを順番に実行し、アプリケーションを指定の環境にデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | setup | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。|
| git-checkout-ssh | setup | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。|
| compile-design-pattern | setup | git-checkout | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、Application Manifestを生成します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがgithub, gitlabの場合に作成されます。|
| compile-design-pattern-ssh | setup | git-checkout-ssh | リポジトリ内の QVS Config に記載されている Cloud Native Adapter をコンパイルし、Application Manifestを生成します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucket, backlogの場合に作成されます。|
| deployment-worker | setup | compile-design-pattern or compile-design-pattern-ssh | コンパイルされたApplication Manifestを指定の環境にデプロイします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:simpleSetup
    pipelineParams:
      repositoryKind: gitlab
      resourcePriority: high
  - pattern: qmonus.net/adapter/official/pipeline/deploy:simpleDeploy # simpleDeployをともに宣言することで、Qmonus Value Streamで段階的なデプロイを行うことができるPipeline/Taskを生成する
    pipelineParams:
      repositoryKind: gitlab
      resourcePriority: high
```

## Code
[deploy:simpleSetup](../../pipeline/deploy/simpleSetup.cue)
