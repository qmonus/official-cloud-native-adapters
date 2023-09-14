# GCP Image Promotion Adapter
Qmonus Value Streamを用いて、コンテナレジストリに保存されたイメージを別のコンテナレジストリにコピーするAdapterです。検証環境から商用環境へイメージをコピーするためにご利用いただけます。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/utils:imagePromoteGcp`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
コンテナレジストリとしてContainer Registry/Artifact Registryを使用することが前提になります。

Qmonus Value Streamへ認証情報を登録するサービスアカウントの権限として、コンテナレジストリの種類に対して以下の Role または同じ権限を持つカスタムロールが事前準備として必要になります。

* コピー元のレジストリに対する権限:
  * Container Registry: `roles/storage.objectViewer`
  * Artifact Registry: `roles/artifactregistry.reader`

* コピー先のレジストリに対する権限:
  * Container Registry: `roles/storage.admin`
  * Artifact Registry: `roles/artifactregistry.writer`


## Platform
Container Registry/Artifact Registry, Google Cloud
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成されるTaskのimage-promoteに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のイメージを指定してValue Streamを実行する際、本パラメータにコピーするイメージ名を指定することでTaskを区別することができます。| nginx |


### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gcpServiceAccountSecretName | string | yes | - | GCP サービスアカウントのjsonキーを保管しているk8s Secret名 | | yes |
| imageNameFrom | string | yes | - | コピー元のイメージのフルパス | asia-northeast1-docker.pkg.dev/<br>${project_id}/sample/nginx:latest | no |
| imageRegistryPath | string | yes | - | コピーしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス | asia-northeast1-docker.pkg.dev/<br>${project_id}/sample | no |
| imageShortName | string | yes | - | コピーしたコンテナイメージの省略名 | nginx | no |
| imageTag | string | yes | - | コンテナイメージのタグ名 | v1.0.0 | no |

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| imageFullNameTag  | string | コピー後のイメージ名のフルパスにタグ名を加えたもの | asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx:latest |
| imageFullNameDigest  | string | コピー後のイメージ名のフルパスにダイジェスト値を加えたもの | asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx@sha256:xxxxxxxxxxxx |
| imageDigest  | string | コピー後のイメージのダイジェスト値 | sha256:xxxxxxxxxxxx |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| promote | image-promote のTaskを実行し、コンテナイメージをコピーします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| image-promote | build | - | 指定されたコンテナイメージを別のレジストリにコピーします。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/utils:imagePromoteGcp
```

## Code
[utils:imagePromoteGcp](../../pipeline/utils/imagePromoteGcp.cue)
