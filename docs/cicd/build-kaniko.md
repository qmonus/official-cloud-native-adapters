# Kaniko Adapter
Qmonus Value Streamを用いて、指定のGitリポジトリに格納されているDockerfileからDockerイメージをビルドしてコンテナレジストリにプッシュするためのCloud Native Adapterです。デフォルトではリモートキャッシュを使用しないため、Artifact Registryだけでなく、[GCP Buildkit Adapter](./build-buildkitGcp.md)でキャッシュの格納に対応していない関係で使用することができないContainer Registryにもイメージをプッシュすることが可能です。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/build:kaniko`


## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
Qmonus Value Streamへ認証情報を登録するサービスアカウントの権限として、コンテナレジストリの種類に対して以下の Role または同じ権限を持つカスタムロールが事前準備として必要になります。
* Artifact Registry: `roles/artifactregistry.writer`
* Container Registry: `roles/storage.admin`
  
## Platform
Google Cloud
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image  | string | no | "" | 生成されるkaniko-build-push Taskに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |
| repositoryKind  | string | no | "" | ソースコードの管理に使用しているGitリポジトリの種類を指定してください。サポートしているのは、github, gitlab, bitbucket, backlog で、何も指定されない場合はgithub用の設定になります。 | gitlab |
| buildArgs  | struct | no | [] | Dockerfileで使用するパラメータを指定することができます。 | [Usage](#usage)を参考にしてください。 |
| useSshKey  | bool | no | false | trueを指定するとGitリポジトリをクローンするための認証にSSH Keyを使用するように設定できます。 | true |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gitCloneUrl  | string | yes | - | GitリポジトリサービスのURL | https://github.com/${organization}/<br>${repository} | yes |
| gitRevision  | string | yes | - | Gitのリビジョン | | no |
| gitRepositoryDeleteExisting  | bool | no | true | trueの場合、Git Checkoutする時に指定先のディレクトリが存在している場合に削除する |  | no |
| gitCheckoutSubDirectory | string | no | "" | GitのCheckout作業をするパス名 | | no |
| gitTokenSecretName | string | yes | - | Gitのアクセストークンを保管しているk8s Secret名 | | yes |
| gitSshKeySecretName | string | yes | - | GitのSSH Keyを保管しているk8s Secret名 | | yes |
| pathToDockerFile  | string | no | Dockerfile | ビルドに使用するDockerfileのファイル名 | | no |
| pathToContext  | string | no | "." | Dockerfileが置かれているディレクトリへのパス | | no |
| imageRegistryPath  | string | yes | - | buildしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス | asia.gcr.io/${project_id}/sample | no |
| imageShortName  | string | yes | "" | ビルドするコンテナイメージの省略名 | nginx | no |
| imageTag  | string | no | - | ビルドするイメージ名に付与するtag名 | v1.0.0 | no |
| gcpServiceAccountSecretName  | string | yes | - | 指定したコンテナレジストリへの認証を行うためのGCPサービスアカウントキー | | yes |
| kanikoOptions  | string | no | "" | kanikoでイメージをビルドする際に追加で設定するオプション | --verbosity=debug | no |

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| imageFullNameTag  | string | イメージ名のフルパスにタグ名を加えたもの | asia.gcr.io/${project_id}/nginx:latest |
| imageFullNameDigest  | string | イメージ名のフルパスにダイジェスト値を加えたもの | asia.gcr.io/${project_id}/nginx@sha256:xxxxxxxxxxxx |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| build  | git-checkout(-ssh), kaniko-build-push  のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | build | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがbitbucket以外の場合に作成されます。|
| git-checkout-ssh | build | - | repositoryKindが指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucketの場合に作成されます。|
| kaniko-build-push | build | git-checkout or git-checkout-ssh | Dockerfileからイメージをビルドし、コンテナレジストリへプッシュします。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/build/kaniko
    pipelineParams:
      buildArgs: # Dockerfile内にpip_install_optionsというパラメータ名に対して"--cache-dir=/cache/.pip"という値を格納する
        pip_install_options: # kanikoで--build-arg で指定するDockerfile内で使用するパラメータ名
           name: "pipInstallOptions" # Pipeline/Taskでのパラメータ名
           default: "--cache-dir=/cache/.pip" # kanikoで--build-arg で指定する実際のパラメータの値
```

## Code
[build:kaniko](../../pipeline/build/kaniko.cue)
