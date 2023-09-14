# AWS Buildkit Adapter
Qmonus Value Streamを用いて、Gitリポジトリに格納されているDockerfileからコンテナイメージをビルドし、コンテナレジストリにプッシュするためのCloud Native Adapterです。
[GCP Buildkit Adapter](./build-buildkitGcp.md)と同等な機能をもつCloud Native AdapteでAWSに対応しているものとなっています。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/build:buildkitAws`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
コンテナレジストリとしてElastic Container Registryを使用することが前提になります。

Qmonus Value Streamへ認証情報を登録するIAMの権限として、使用するコンテナレジストリに対して以下が必要になります。
* Elastic Container Registry: `AmazonEC2ContainerRegistryPowerUser`

以下の手順でQmonus Value StreamのCredentialの作成が必要です。  

1. 必要な権限を付与したECR用のIAMユーザでアクセスキーを作成し、  
   アクセスキーID、シークレットアクセスキーを取得
2. Qmonus Value Stream上で以下のCredentialを作成
   * Name: (任意の名前) 
   * Description: (任意の文章または空白)
   * Key: credentials
   * Value: 1. で取得したアクセスキーの情報を以下の形式で設定
      ```
      [default]
      aws_access_key_id = 【アクセスキーID】
      aws_secret_access_key = 【シークレットアクセスキー】
      ```
3. Deployment Configの`awsCredentialName`に2. で登録したCredentialのNameを設定  

### Constraints
ECRはcache manifestをサポートしていないため、ビルド時にキャッシュは利用できません。

## Platform
Elastic Container Registry, Amazon Web Services
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成される2つのTaskのdocker-login-aws, buildkitに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |
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
| awsCredentialName | string | yes | - | IAMユーザのアクセスキーを保管しているk8s Secret名 | | no |
| awsProfile | string | no | default | ECRのログインに使用するプロファイル名 | | no |
| awsRegion | string | yes | - | ECRが所属するリージョン名 | | no |
| containerRegistry | string | yes | "" | コンテナレジストリのエンドポイント | xxxxxxxxxxxx.dkr.ecr.ap-northeast-1.amazonaws.com | no |
| dockerfile | string | yes | Dockerfile | ビルドするdockerfileのファイル名 | | no |
| imageRegistryPath | string | yes | - | ビルドしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス | xxxxxxxxxxxx.dkr.ecr.ap-northeast-1.amazonaws.com | no |
| imageShortName | string | yes | - | ビルドするコンテナイメージの省略名。ECRのリポジトリ名を指定する。 | nginx | no |
| imageTag | string | yes | - | コンテナイメージのタグ名 | v1.0.0 | no |
| pathToContext | string | yes | . | ソースディレクトリからの相対パス | | no |
| extraArgs | string | yes | "" | Buildkitでイメージをビルドする際に追加で設定するオプション | --opt build-arg:foo=var | no |

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| imageFullNameTag  | string | イメージ名のフルパスにタグ名を加えたもの | xxxxxxxxxxxx.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:v1.0.0 |
| imageFullNameDigest  | string | イメージ名のフルパスにダイジェスト値を加えたもの | xxxxxxxxxxxx.dkr.ecr.ap-northeast-1.amazonaws.com/nginx@sha256:xxxxxxxxxxxx |
| imageDigest  | string | イメージのダイジェスト値 | sha256:xxxxxxxxxxxx |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| build | git-checkout(-ssh), docker-login-aws, buildkit  のTaskを順番に実行し、Dockerfileからイメージのビルドとプッシュを行います。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| git-checkout | build | - | 指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはGit Tokenを使用します。AdapterOptionsのuseSshKeyがFalseかつrepositoryKindがbitbucket以外の場合に作成されます。|
| git-checkout-ssh | build | - | repositoryKindが指定のGitリポジトリをクローンし、対象のリビジョン・ブランチにチェックアウトします。クローンする際の認証にはSSH Keyを使用します。AdapterOptionsのuseSshKeyがTrueまたはrepositoryKindがbitbucketの場合に作成されます。|
| docker-login-aws| build | git-checkout or git-checkout-ssh | 指定したElastic Container Registryへの認証を行います。|
| buildkit | build | docker-login-aws | Dockerfileからイメージをビルドし、コンテナレジストリへプッシュします。|

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/build:buildkitAws
```

## Code
[build:buildkitAws](../../pipeline/build/buildkitAws.cue)
