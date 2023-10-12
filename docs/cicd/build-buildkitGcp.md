# GCP Buildkit Adapter
Qmonus Value Streamを用いて、Gitリポジトリに格納されているDockerfileからコンテナイメージをビルドし、コンテナレジストリにプッシュするためのCloud Native Adapterです。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/build:buildkitGcp`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
コンテナレジストリとしてArtifact Registryを使用することが前提になります。

Qmonus Value Streamへ認証情報を登録するサービスアカウントの権限として、コンテナレジストリの種類に対して以下の Role または同じ権限を持つカスタムロールが事前準備として必要になります。
* Artifact Registry: `roles/artifactregistry.writer`

## Platform
Artifact Registry, Google Cloud
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成される2つのTaskのdocker-login-gcp, buildkitに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |
| repositoryKind  | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab |
| useSshKey  | bool | no | false | trueを指定するとリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。 | true |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl  | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | | yes |
| gitSshKeySecretName | string | yes | - | GitのSSH Keyを保管しているk8s Secret名 | | yes |
| gcpServiceAccountSecretName | string | yes | - | GCP サービスアカウントのjsonキーを保管しているk8s Secret名 | | yes |
| gcpProjectId | string | yes | - | GCPのプロジェクト名 | | yes |
| dockerfile | string | yes | Dockerfile | ビルドするdockerfileのファイル名 | | no |
| imageRegistryPath | string | yes | - | ビルドしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス | asia-northeast1-docker.pkg.dev/<br>${project_id}/sample | no |
| imageShortName | string | yes | - | ビルドするコンテナイメージの省略名 | nginx | no |
| imageTag | string | yes | - | コンテナイメージのタグ名。buildcacheというタグ名は予約されているため指定できません。 | v1.0.0 | no |
| pathToContext | string | yes | . | ソースディレクトリからの相対パス | | no |
| extraArgs | string | yes | "" | Buildkitでイメージをビルドする際に追加で設定するオプション | --opt build-arg:foo=var | no |

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| imageFullNameTag  | string | イメージ名のフルパスにタグ名を加えたもの | asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx:latest |
| imageFullNameDigest  | string | イメージ名のフルパスにダイジェスト値を加えたもの | asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx@sha256:xxxxxxxxxxxx |
| imageDigest  | string | イメージのダイジェスト値 | sha256:xxxxxxxxxxxx |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| build | git-checkout(-ssh), docker-login-gcp, buildkit  のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | build | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがbitbucket以外の場合に作成されます。|
| git-checkout-ssh | build | - | repositoryKindが指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucketの場合に作成されます。|
| docker-login-gcp| build | git-checkout or git-checkout-ssh | 指定したArtifact Registryへの認証を行います。|
| buildkit | build | docker-login-gcp | Dockerfileからイメージをビルドし、コンテナレジストリへプッシュします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/build:buildkitGcp
```

## Code
[build:buildkitGcp](../../pipeline/build/buildkitGcp.cue)
