# Azure Buildkit Adapter
Qmonus Value Streamを用いて、Gitリポジトリに格納されているDockerfileからコンテナイメージをビルドし、コンテナレジストリにプッシュするためのCloud Native Adapterです。
[build:buildkitGcp](../../pipeline/build/buildkitGcp.cue)と同等な機能をもつCloud Native AdapteでAzureに対応しているものとなっています。

## Module
- Module: `qmonus.net/adapter/official`
- Version: `v0.3.0`
- Import path `qmonus.net/adapter/official/pipeline/build:buildkitAzure`

## Level
Best Practice: ベストプラクティスにもとづく実装


### Prerequisites
コンテナレジストリとしてAzure Container Registryを使用することが前提になります。

Qmonus Value Streamへ認証情報を登録するサービスプリンシパルの権限として、使用するコンテナレジストリに対して以下が必要になります。
* Artifact Registry: 組み込みロールの場合は`AcrPush`

## Platform
Microsoft Azure
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| image | string | no | "" | 生成される2つのTaskのdocker-login-azure, buildkitに接頭語を付与します。また、resultsの値が格納されている変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。(e.g. test)|

### Parameters
| Parameter Name | Type | Required | Default | Description | Auto Binding |
| --- | --- | --- | --- | --- | --- |
| gitRepositoryUrl  | string | yes | - | GitリポジトリサービスのURL(プロトコルは含まない) | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | yes |
| containerRegistry | string | yes | "" | コンテナレジストリのエンドポイント | no |
| azServicePrincipalSecretName | string | yes | "" | Azure Active Directory のサービスプリンシパルを保管しているk8s Secret名 | no |
| imageRegistryPath | string | no | - | ビルドしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス (e.g. asia.gcr.io/${project_Id}/sample ) | no |
| cacheImageName | string | yes | - | ビルドする際のキャッシュの出力先asia.gcr.io/${project_Id}/sample/nginx:buildcache ) | no |
| dockerfile | string | yes | Dockerfile | ビルドするdockerfileのファイル名 | no |
| imageShortName | string | yes | - | ビルドするコンテナイメージの省略名（e.g. nginx）  | no |
| imageTag | string | yes | - | コンテナイメージのタグ名 (e.g. v0.0.1) | no |
| pathToContext | string | yes | . | ソースディレクトリからの相対パス | no |
| extraArgs | string | yes | "" | Buildkitでイメージをビルドする際に追加で設定するオプション | no |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| build | git-checkout, docker-login-azure, buildkit のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | build | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。|
| docker-login-azure | build | git-checkout | 指定したAzure Container Registryへの認証を行います。|
| buildkit | build | docker-login-azure | Dockerfileからイメージをビルドし、コンテナレジストリへプッシュします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/build:buildkitAzure
```

## Code
[build:buildkitAzure](../../pipeline/build/buildkitAzure.cue)
