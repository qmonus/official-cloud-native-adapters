# Azure Buildkit Adapter
Qmonus Value Streamを用いて、Gitリポジトリに格納されているDockerfileからコンテナイメージをビルドし、コンテナレジストリにプッシュするためのCloud Native Adapterです。
[GCP Buildkit Adapter](./build-buildkitGcp.md)と同等な機能をもつCloud Native AdapteでAzureに対応しているものとなっています。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/build:buildkitAzure`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
コンテナレジストリとしてAzure Container Registryを使用することが前提になります。

Qmonus Value Streamへ認証情報を登録するサービスプリンシパルの権限として、使用するコンテナレジストリに対して以下が必要になります。
* Azure Container Registry: 組み込みロールの場合は`AcrPush`

## Platform
Azure Container Registry, Microsoft Azure
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成される2つのTaskのdocker-login-azure, buildkitに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |
| repositoryKind  | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab |
| useSshKey  | bool | no | false | trueを指定するとリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。 | true |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | | yes |
| gitSshKeySecretName | string | yes | - | GitのSSH Keyを保管しているk8s Secret名 | | yes |
| azureApplicationId | string | yes | - | AzureのApplicationID | | yes |
| azureClientSecretName | string | yes | - | AzureのClientSecretを保管しているSecret名 | | yes |
| dockerfile | string | yes | Dockerfile | ビルドするdockerfileのファイル名 | | no |
| imageRegistryPath | string | yes | - | コピー元のコンテナレジストリの完全修飾名。コンテナレジストリのログインサーバを指定してください。[名前空間](https://learn.microsoft.com/ja-jp/azure/container-registry/container-registry-best-practices#repository-namespaces) を利用する場合、${acr_name}.azurecr.io/\<repositry name\> の形式で入力することで、\<repositry name\> を名前空間としたパスでイメージをPushします。 | ${acr_name}.azurecr.io <br><br>名前空間を使用する場合は<br> ${acr_name}.azurecr.io/service1 | no |
| imageShortName | string | yes | - | ビルドするコンテナイメージの省略名。ACRのリポジトリ名を指定する。| nginx | no |
| imageTag | string | yes | - | コンテナイメージのタグ名。buildcacheというタグ名は予約されているため指定できません。 | v1.0.0 | no |
| pathToContext | string | yes | . | ソースディレクトリからの相対パス | | no |
| extraArgs | string | yes | "" | Buildkitでイメージをビルドする際に追加で設定するオプション | | no |

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| imageFullNameTag  | string | イメージ名のフルパスにタグ名を加えたもの | ${acr_name}.azurecr.io/sample/nginx:latest |
| imageFullNameDigest  | string | イメージ名のフルパスにダイジェスト値を加えたもの | ${acr_name}.azurecr.io/sample/nginx@sha256:xxxxxxxxxxxx |
| imageDigest  | string | イメージのダイジェスト値 | sha256:xxxxxxxxxxxx |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| build | git-checkout(-ssh), docker-login-azure, buildkit のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | build | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがbitbucket以外の場合に作成されます。|
| git-checkout-ssh | build | - | repositoryKindが指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucketの場合に作成されます。|
| docker-login-azure | build | git-checkout or git-checkout-ssh | 指定したAzure Container Registryへの認証を行います。|
| buildkit | build | docker-login-azure | Dockerfileからイメージをビルドし、コンテナレジストリへプッシュします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/build:buildkitAzure
```

## Code
[build:buildkitAzure](../../pipeline/build/buildkitAzure.cue)
