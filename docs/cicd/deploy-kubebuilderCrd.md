# Kubebuilder CRD Deploy Adapter
Qmonus Value Streamを用いて、Kustomizeで管理されたCRD（Custom Resource Definition）マニフェストをユーザーの実行環境にデプロイするためのCloud Native Adapterです。
ユーザーがkubebuilderを使用してCRDとコントローラを定義し、CRDを本AdapterのPipeline/Taskでデプロイしつつ、[Kustomization Deploy Adapter](./deploy-kustomization.md)のPipeline/Taskでコントローラをデプロイするケースを想定しています。使用例は[Usage](#usage) を参照してください。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/deploy:kubebuilderCrdInstall`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
* 別途、git-checkout Taskが実行される、[Kustomization Deploy Adapter](./deploy-kustomization.md)で生成されるPipelineをApplyする必要があります。

* Gitリポジトリの config/crd ディレクトリ上に、本Adapterでデプロイする構成を記述した、kustomizeの設定ファイルであるkustomization.yamlを配置する必要がります。

## Platform
General / Platform Free

## Parameters

### Adapter Options
None

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| pathToSource | string | no | "" | ソースディレクトリからの相対パス | | no |
| kubeconfigSecretName | string | yes | - | QVSにおけるDeploymentの作成時に指定したkubeconfigを保管しているk8s Secret名 | | yes |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| deploy  | **Kustomization Deploy Adapterで別途Applyされたgit-checkout Taskの後に**、kubebuilder-crd-installのTaskを実行し、Kustomizeで管理されたCRDマニフェストを指定の環境にデプロイします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| kubebuilder-crd-install | deploy | git-checkout | Kustomizeで管理されたCRDマニフェストを指定の環境にデプロイします。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/deploy:kustomization # Kustomization Deploy Adapter も共に宣言することで、本Adapterが機能する
  - pattern: qmonus.net/adapter/official/pipeline/deploy:kubebuilderCrdInstall
```

## Code
[deploy:kubebuilderCrdInstall](../../pipeline/deploy/kubebuilderCrdInstall.cue)
