# GCP Container Image Scanning Adapter
Qmonus Value Streamを用いて、コンテナレジストリのイメージに対して脆弱性診断を実行するためのCloud Native Adapterです。

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/pipeline/scan:trivyGcp`

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
| shouldNotify | bool | no | False | 脆弱性診断の結果をSlackで通知するか | True |

> **Warning**
>
> 脆弱性が検知されなかった場合でもSlackで通知されますが、今後は脆弱性が発見された場合のみ通知する仕様に修正する予定です。

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gcpServiceAccountSecretName | string | yes | - | GCP サービスアカウントのjsonキーを保管しているk8s Secret名 | | yes |
| imageName | string | yes | - | コンテナレジストリのイメージ名のフルパス | asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx:latest<br>or<br>asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx@sha256:xxxxxxxxxxxx | no |
| mentionTarget | string | no | "" | Slackへ通知するメッセージのメンション先。**ユーザやグループのID**を指定する必要があります | <@U024BE7LH> or <!subteam^SAZ94GDB8> or <!here> | no |

Slackのメンションの詳細については、[ドキュメント](https://api.slack.com/reference/surfaces/formatting#advanced)をご確認ください。


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
| dump-result | scan | - | 脆弱性診断の結果を出力します。 |
| notice-result | scan | - | 脆弱性診断の結果をSlackで通知します。Adapter OptionsのshouldNotifyをTrueにした場合に生成されます。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/scan:trivyGcp
```

## Code
[imageScan:trivyGcp](../../pipeline/scan/trivyGcp.cue)
