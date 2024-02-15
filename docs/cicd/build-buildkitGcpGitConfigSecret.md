# GCP Buildkit Git Config Secret Adapter
Qmonus Value Streamを用いて、Gitリポジトリに格納されているDockerfileからコンテナイメージをビルドし、コンテナレジストリにプッシュするためのCloud Native Adapterです。

[GCP Buildkit Adapter](./build-buildkitGcp.md)との相違点として、Qmonus Value Streamで登録したGit Tokenを設定したGit ConfigファイルをDockerfileにマウントします。

例として以下のコードをDockerfileに追加することで、ビルド時にプライベートなGitリポジトリをクローンすることができます。

```Dockerfile
RUN --mount=type=secret,id=gitconfig,dst=/root/.gitconfig git clone https://github.com/${organization}/${repository}
```

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/build:buildkitGcpGitConfigSecret`

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
| image | string | no | "" | 生成される2つのTaskのdocker-login-gcp, buildkit-git-config-secretに接頭語を付与します。また、resultsの値が格納されている変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |
| repositoryKind  | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab で、何も指定されない場合はgithub用の設定になります。 | gitlab |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl  | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision  | string | yes | - | Gitのリビジョン |  | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する |  | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 |  | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 |  | yes |
| gcpServiceAccountSecretName | string | yes | - | GCP サービスアカウントのjsonキーを保管しているk8s Secret名 |  | yes |
| gcpProjectId | string | yes | - | GCPのプロジェクト名 |  | yes |
| dockerfile | string | yes | Dockerfile | ビルドするDockerfileのファイル名 |  | no |
| imageRegistryPath | string | yes | - | ビルドしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス | asia-northeast1-docker.pkg.dev/<br>${project_id}/sample | no |
| imageShortName | string | yes | - | ビルドするコンテナイメージの省略名 | nginx | no |
| imageTag | string | yes | - | コンテナイメージのタグ名。buildcacheというタグ名は予約されているため指定できません。 | v1.0.0 | no |
| pathToContext | string | yes | . | ソースディレクトリからの相対パス |  | no |
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
| build | git-checkout, init-git-credentials, docker-login-gcp, buildkit-git-config-secret のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | build | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。|
| init-git-credentials | build | git-checkout | Git ConfigファイルにGit Tokenを設定します。 |
| docker-login-gcp | build | init-git-credentials | 指定したコンテナレジストリへの認証を行います。|
| buildkit-git-config-secret | build | docker-login-gcp | Git ConfigファイルをマウントしたDockerfileからイメージをビルドし、コンテナレジストリへプッシュします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/build:buildkitGcpGitConfigSecret
```

## Code
[build:buildkitGcpGitConfigSecret](../../pipeline/build/buildkitGcpGitConfigSecret.cue)
