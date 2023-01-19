# GCP Container Image Scanning Adapter
Qmonus Value Streamを用いて、コンテナレジストリのイメージに対して脆弱性診断を実行するためのCloud Native Adapterです。

## Module
- Module: `qmonus.net/adapter/official`
- Version: `v0.6.0`
- Import path `qmonus.net/adapter/official/pipeline/scan:trivyGcp`

## Level
Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites
コンテナレジストリとしてContainer Registry/Artifact Registryを使用することが前提になります。

Qmonus Value Streamへ認証情報を登録するサービスアカウントの権限として、コンテナレジストリの種類に対して以下の Role または同じ権限を持つカスタムロールが事前準備として必要になります。
* Container Registry: `roles/storage.objectViewer`
* Artifact Registry: `roles/artifactregistry.reader`

## Platform
Container Registry/Artifact Registry, Google Cloud Platform
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成されるTaskのtrivy-image-scanに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gcpServiceAccountSecretName | string | yes | - | GCP サービスアカウントのjsonキーを保管しているk8s Secret名 | | yes |
| imageName | string | yes | - | コンテナレジストリのイメージ名のフルパス | asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx:latest<br>or<br>asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx@sha256:xxxxxxxxxxxx | no |

### Results Parameters

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| scan | trivy-image-scanのTaskを実行し、コンテナイメージの脆弱性診断を実行します。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| trivy-image-scan | scan | - | 指定のコンテナレジストリのイメージに対して、Trivyによる脆弱性診断を実行します。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/scan:trivyGcp
```

## Code
[imageScan:trivyGcp](../../pipeline/scan/trivyGcp.cue)
