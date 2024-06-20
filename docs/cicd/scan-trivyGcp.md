# GCP Container Image Scanning Adapter
Qmonus Value Streamを用いて、コンテナレジストリのイメージに対して脆弱性診断を実行するためのCloud Native Adapterです。

## Platform
Google Cloud

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

## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成されるTaskのtrivy-image-scan-gcpに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |
| shouldNotify | bool | no | false | trueを指定すると、Slack通知を設定したAssemblyLineを用いて本Adapterを利用した際に、脆弱性診断の結果をSlackで通知します。AssemblyLineにSlack通知を設定する方法については [ドキュメント](https://docs.valuestream.qmonus.net/guide/slack-notification.html) をご参照ください。 | true |
| resourcePriority | string | no | medium | イメージをスキャンするTekton Task に割り当てるリソース量を設定します。 medium もしくは high のいずれかを設定でき、それぞれの割り当て量は下記の通りです。<br>・ medium → cpu:0.5, memory: 512MiB <br> ・ high → cpu:1, memory: 1GiB | high |

### Parameters
| Parameter Name | Type | Required | Default | Description                                                                    | Example | Auto Binding |
| --- | --- | --- | --- |--------------------------------------------------------------------------------| --- | --- |
| gcpServiceAccountSecretName | string | yes | - | GCP サービスアカウントのjsonキーを保管しているk8s Secret名                                         | | yes |
| imageName | string | yes | - | コンテナレジストリのイメージ名のフルパス                                                           | asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx:latest<br>or<br>asia-northeast1-docker.pkg.dev/${project_id}/sample/nginx@sha256:xxxxxxxxxxxx | no |
| severity | string | no | CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN | スキャン対象の脆弱性の重大度を指定します。例えば、HIGH,CRITICALを指定した場合、HIGH, CRITICAL以外の重大度の脆弱性はレポート対象から除外されます。 | CRITICAL,HIGH | no |
| ignoreVulnerability | string | no | false | true を指定すると、脆弱性が見つかってもPipelineは失敗せずに後続の処理を継続できます。                              | true | no |
| extraImageScanOptions | string | no | "" | Trivy scan実行時に追加で設定するオプション。`--no-progress`, `--output`, `--format`, `--severity`, `--exit-code` オプションはデフォルトで使用されているため、設定しないでください。 | --timeout 60m --scanners vuln | no |
| mentionTarget | string | no | "" | Slackへ通知するメッセージのメンション先。**ユーザやグループのID**を指定する必要があります                             | <@U024BE7LH> or <!subteam^SAZ94GDB8> or <!here> | no |

Slackのメンションの詳細については、[ドキュメント](https://api.slack.com/reference/surfaces/formatting#advanced)をご確認ください。

### Results Parameters

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| scan | trivy-image-scan-gcpのTaskを実行し、コンテナイメージの脆弱性診断を実行します。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| trivy-image-scan-gcp | scan | - | 指定のコンテナレジストリのイメージに対して、Trivyによる脆弱性診断を実行して診断結果を出力します。Adapter OptionsのshouldNotifyをtrueにした場合、診断結果をSlackで通知します。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/scan:trivyGcp
```

## Code
[imageScan:trivyGcp](../../pipeline/scan/trivyGcp.cue)
