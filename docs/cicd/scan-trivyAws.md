# AWS Container Image Scanning Adapter
Qmonus Value Streamを用いて、コンテナレジストリのイメージに対して脆弱性診断を実行するためのCloud Native Adapterです。

## Platform
AWS

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/pipeline/scan:trivyAws`

## Level
Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites

- コンテナレジストリとしてAmazon ECRを使用することが前提になります。

- 事前にIAMユーザーを作成し、Qmonus Value Streamへ認証情報を登録する必要があります。以下のポリシーをIAMユーザーに付与してください。
    - `AmazonEC2ContainerRegistryPullOnly`
    - `AmazonS3FullAccess`
        - Adapter Optionsで `uploadScanResults: true` を指定する場合のみ、必要になります。
    - `AWSSecurityHubFullAccess`
        - Adapter Optionsで `useSecurityHub: true` を指定する場合のみ、必要になります。

- Adapter Optionsで `useSecurityHub: true` を指定する場合は、事前に、使用するAWSリージョンにおいてAWS Security Hubを有効化し、[Aqua Security – Aqua Cloud Native Security Platformとの統合](https://docs.aws.amazon.com/ja_jp/securityhub/latest/userguide/securityhub-partner-providers.html) を有効化しておく必要があります。詳細は [公式ドキュメント](https://docs.aws.amazon.com/ja_jp/securityhub/latest/userguide/securityhub-integration-enable.html) をご参照ください。

### Constraints

- Adapter Optionsで `useSecurityHub: true` を指定する場合は、重大度がCRITICALまたはHIGHとなる全ての脆弱性情報がSecurity Hubに送信されます。
    - 本Adapterのパラメータ `severity` や `extraImageScanOptions` を設定して、スキャンによって検出される脆弱性の対象範囲を制限している場合であっても、Security Hubに送信される脆弱性情報に関してはこの制限は適用されません。

- Adapter Optionsで `useSecurityHub: true` を指定する場合は、Security Hubに送信される脆弱性情報における以下の属性の値が、それぞれ以下の値になります。
    - ID
        - `{imageName に設定した値}/{CVE ID}/{脆弱性が検出されたパッケージ名}`
    - コンテナイメージ名
        - `{imageName に設定した値}`
    - リソース ID
        - `{imageName に設定した値}`

## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成されるTaskのtrivy-image-scan-awsに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のビルド Taskを使用してValue Streamを実行する際、本パラメータにビルドするイメージ名を指定することでTaskを区別することができます。| nginx |
| sbomFormat | string | no | cyclonedx | 出力するSBOMファイルのフォーマットを指定します。cyclonedx, spdx, spdx-jsonのいずれかを設定できます。| sdpx-json |
| uploadScanResults | bool | no | false | trueを指定すると、スキャン結果のファイルを指定されたAmazon S3バケットにアップロードします。| true |
| useSecurityHub | bool | no | false | trueを指定すると、重大度がCRITICALまたはHIGHとなる全ての脆弱性情報をSecurity Hubに送信します。`severity` や `extraImageScanOptions` によって、検出される脆弱性の対象範囲が制限されている場合であっても、Security Hubに送信される脆弱性情報に関しては、その制限の影響を受けません。 | true |
| shouldNotify | bool | no | false | trueを指定すると、Slack通知を設定したAssemblyLineを用いて本Adapterを利用した際に、脆弱性診断の結果をSlackで通知します。AssemblyLineにSlack通知を設定する方法については [ドキュメント](https://docs.valuestream.qmonus.net/guide/notification/slack-notification) をご参照ください。 | true |
| resourcePriority | string | no | medium | イメージをスキャンするTekton Task に割り当てるリソース量を設定します。 medium もしくは high のいずれかを設定でき、それぞれの割り当て量は下記の通りです。<br>・ medium → cpu:0.5, memory: 512MiB <br> ・ high → cpu:1, memory: 1GiB | high |

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| awsCredentialName | string | yes | - | AWSのIAMユーザーの認証情報を保管しているSecret名 | aws-default-xxxxxxxxxxxxxxxxxxxx | yes |
| awsAccountId | string | yes | - | AWSリソースが所属するアカウントID。Adapter Optionsで `useSecurityHub: true` と指定した時のみ設定する必要があります。 | "012345678912" | yes |
| awsRegion | string | yes | - | AWSリソースが所属するリージョン名 | ap-northeast-1 | yes |
| imageName | string | yes | - | コンテナレジストリのイメージ名のフルパス | xxxxxxxxxxxx.dkr.ecr.ap-northeast-1.amazonaws.com/nginx:latest | no |
| severity | string | no | CRITICAL,HIGH,MEDIUM,LOW,UNKNOWN | スキャン対象の脆弱性の重大度を指定します。例えば、HIGH,CRITICALを指定した場合、HIGH, CRITICAL以外の重大度の脆弱性はレポート対象から除外されます。 | CRITICAL,HIGH | no |
| ignoreVulnerability | string | no | false | true を指定すると、脆弱性が見つかってもPipelineは失敗せずに後続の処理を継続できます。 | true | no |
| extraImageScanOptions | string | no | "" | Trivy scan実行時に追加で設定するオプション。`--no-progress`, `--output`, `--format`, `--severity`, `--exit-code` オプションはデフォルトで使用されているため、設定しないでください。 | --timeout 60m --scanners vuln | no |
| scanResultsS3BucketName | string | yes | - | スキャン結果のアップロード先のS3バケット名。Adapter Optionsで `uploadScanResults: true` と指定した時のみ設定する必要があります。 | scan-results | no |
| mentionTarget | string | no | "" | Slackへ通知するメッセージのメンション先。**ユーザやグループのID**を指定する必要があります | <@U024BE7LH> or <!subteam^SAZ94GDB8> or <!here> | no |

Slackのメンションの詳細については、[ドキュメント](https://api.slack.com/reference/surfaces/formatting#advanced)をご確認ください。

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| uploadedScanResultsUrl | string | スキャン結果のアップロード先のURL | `https://ap-northeast-1.console.aws.amazon.com/s3/buckets/scan-results?prefix=xxxxxxxxxxxx.dkr.ecr.ap-northeast-1.amazonaws.com/nginx/latest/` |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| scan | trivy-image-scan-awsのTaskを実行し、コンテナイメージの脆弱性診断を実行します。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| trivy-image-scan-aws | scan | - | 指定のコンテナレジストリのイメージに対して、Trivyによる脆弱性診断を実行して診断結果を出力します。Adapter OptionsのuploadScanResultsにtrueを指定した場合はscanResultsS3BucketNameで指定したS3バケットにスキャン結果をアップロードします。また、useSecurityHubをtrueにした場合はスキャン結果をawsAccountIdで指定したAWSアカウントのSecurity Hubに送信します。加えて、shouldNotifyをtrueにした場合、診断結果をSlackで通知します。 |

## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/scan:trivyAws
    pipelineParams:
      uploadScanResults: true
      useSecurityHub: true
      shouldNotify: true
```

## Code
[imageScan:trivyAws](../../pipeline/scan/trivyAws.cue)
