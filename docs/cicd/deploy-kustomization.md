# Kustomization Deploy Adapter
Qmonus Value Streamを用いて、Kustomizeで管理されたマニフェストをユーザーの実行環境にデプロイするためのCloud Native Adapterです。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/deploy:kustomization`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
GitリポジトリにはKustomizeで管理されたマニフェストを含める必要があります。

```
# 例
Git repository
├── base/
│   ├── configMap.yaml
│   ├── deployment.yaml
│   ├── kustomization.yaml
│   ├── service.yaml
│   └── …
└── overlays/
    ├── production
    |    ├── kustomization.yaml
    |    └── …
    └── statging
         ├── kustomization.yaml
         └── …
```

## Platform
General / Platform Free

## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| repositoryKind  | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github または gitlab で、何も指定されない場合はgithub用の設定になります。| gitlab |

### Parameters
| Parameter Name | Type | Required | Default | Description | Auto Binding | Example |
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl  | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | | yes |
| replaceTargetImageName | string | no | "" | 置換対象のコンテナイメージ名(指定がない場合は置換はスキップされる) | | no |
| imageName | string | no | "" | 置換後の新しいコンテナイメージ名(指定がない場合は置換はスキップされる) | | no |
| pathToSource | string | no | "" | ソースディレクトリからの相対パス | | no |
| pathToKustomizationRoot | string | yes | - | Gitリポジトリのルートから `kustomization.yaml` を含むディレクトリへのパス | overlays/staging | no |
| outputFileName | string | no | manifests/output.yaml | `Kustomize build` の結果を出力するファイルのパス(`shared` ディレクトリからの相対パス) | | no |
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
| deploy  | git-checkout, kustomization, deployment-worker  のTaskを順番に実行し、Kustomizeで管理されたソースをコンパイル、指定の環境にデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | deploy | - | 指定のリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。 |
| kustomization | deploy | git-checkout | リポジトリ内のkustomization.yamlを処理し、Application Manifestを生成します。 |
| deployment-worker | deploy | kustomization | コンパイルされたApplication Manifestを指定の環境にデプロイします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:kustomization
    pipelineParams:
      repositoryKind: gitlab
```

## Code
[deploy:kustomization](../../pipeline/deploy/kustomization.cue)
