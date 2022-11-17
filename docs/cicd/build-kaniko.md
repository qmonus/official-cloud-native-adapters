# Kaniko Adapter
Qmonus Value Streamを用いて、指定のGitリポジトリに格納されているDockerfileからDockerイメージをビルドしてコンテナレジストリにプッシュするためのCloud Native Adapterです。デフォルトではリモートキャッシュを使用しないため、Artifact Registryだけでなく、[GCP Buildkit Adapter](./buildkitGcp.md)でキャッシュの格納に対応していない関係で使用することができないContainer Registryにもイメージをプッシュすることが可能です。

## Module
- Module: `qmonus.net/adapter/official`
- Version: `v0.3.0`
- Import path `qmonus.net/adapter/official/pipeline/build:kaniko`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
Qmonus Value Streamへ認証情報を登録するサービスアカウントの権限として、コンテナレジストリの種類に対して以下の Role または同じ権限を持つカスタムロールが事前準備として必要になります。
* Artifact Registry: `roles/artifactregistry.writer`
* Container Registry: `roles/storage.admin`
  
## Platform
Google Cloud Platform
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| image  | string | no | "" | 生成されるkaniko-build-push Taskに接頭語を付与します。また、resultsの値が格納されている変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。|
| repositoryKind  | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。 (e.g. github, gitlab, bitbucket)|
| buildArgs  | struct | no | [] | Dockerfileで使用するパラメータを指定することができます。[Usage](#usage)を参考にしてください。 |
| useSshKey  | bool | no | false | trueを指定するとGitリポジトリをクローンするための認証にsshkeyを使用するように設定できます。 |

### Parameters
| Parameter Name | Type | Required | Default | Description | Auto Binding |
| --- | --- | --- | --- | --- | --- |
| gitRepositoryUrl  | string | yes | - | GitリポジトリサービスのURL(プロトコルは含まない) | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | yes |
| gitSshKeySecretName | string | yes | - | GitのSSH Keyを保管しているk8s Secret名 | yes |
| pathToDockerFile  | string | no | Dockerfile | ビルドに使用するDockerfileのファイル名 | no |
| pathToContext  | string | no | "." | Dockerfileが置かれているディレクトリへのパス | no |
| imageRegistryPath  | string | yes | - | buildしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス (e.g. asia.gcr.io/${project_id}/sample ) | no |
| imageShortName  | string | yes | "" | ビルドするコンテナイメージの省略名（e.g. nginx） | no |
| imageTag  | string | no | latest | ビルドするイメージ名に付与するtag名 | no |
| gcpServiceAccountSecretName  | string | yes | - | 指定したコンテナレジストリへの認証を行うためのGCPサービスアカウントキー | yes |
| kanikoOptions  | string | no | "" | kanikoでイメージをビルドする際に追加で設定するオプション (e.g. --verbosity=debug) | no |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| build  | git-checkout or git-checkout-ssh, kaniko-build-push  のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | build | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがTrueかつrepositoryKindがbitbucket以外の場合に作成されます。|
| git-checkout-ssh | build | - | repositoryKindが指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがFalseまたはrepositoryKindがbitbucketの場合に作成されます。|
| kaniko-build-push | build | git-checkout or git-checkout-ssh | Dockerfileからイメージをビルドし、コンテナレジストリへプッシュします。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/build/kaniko
    pipelineParams:
      buildArgs: # 以下のように設定することで、Dockerfile内にpip_install_optionsというパラメータ名に対して"--cache-dir=/cache/.pip"という値が格納される
        pip_install_options: # kanikoで--build-arg で指定するDockerfile内で使用するパラメータ名
           name: "pipInstallOptions" # Pipeline/Taskでのパラメータ名
           default: "--cache-dir=/cache/.pip" # kanikoで--build-arg で指定する実際のパラメータの値
```

## Code
[build:kaniko](../../pipeline/build/kaniko.cue)
