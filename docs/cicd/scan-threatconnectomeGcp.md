# GCP Threatconnectome Adapter
Qmonus Value Streamを用いて、コンテナレジストリのイメージに対してSBOMを出力して、[Threatconnectome](https://threatconnectome.metemcyber.ntt.com/)にアップロードするためのCloud Native Adapterです。

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/pipeline/scan:threatconnectomeGcp`

## Level
Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites
コンテナレジストリとしてGoogleCloudのContainer Registry/Artifact Registryを使用することが前提になります。
また、[Threatconnectome](https://threatconnectome.metemcyber.ntt.com/)のアカウント及びPTeamが必要になります。

Qmonus Value Streamへ認証情報を登録するサービスアカウントの権限として、コンテナレジストリの種類に対して以下の Role または同じ権限を持つカスタムロールが事前準備として必要になります。
* Container Registry: `roles/storage.objectViewer`
* Artifact Registry: `roles/artifactregistry.reader`

以下の手順でQmonus Value StreamのCredentialの作成が必要です。

1. ThreatconnectomeのRefreshTokenを取得
2. Qmonus Value Stream上で以下のCredentialを作成
    * Name: (任意の名前)
    * Description: (任意の文章または空白)
    * Key: refresh_token
    * Value: 1. で取得したRefreshTokenを設定

## Platform
Container Registry/Artifact Registry, Google Cloud, Threatconnectome
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| groupName | string | no | "$(params.imageShortName)" | ThreatconnectomeにアップロードしたSBOM情報に紐づける名前(リポジトリ名やプロダクト名)となります。[Threatconnectome API](https://api.threatconnectome.metemcyber.ntt.com/api/docs#/pteams/append_pteam_tags_pteams__pteam_id__append_tags_post) | myProduct |


### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| gcpServiceAccountSecretName | string | yes | - | GCP サービスアカウントのjsonキーを保管しているk8s Secret名 | | yes |
| threatconnectomeRefreshTokenName | string | yes | - | ThreatconnectomeのRefreshTokenを保管しているk8s Secret名 | | no |
| threatconnectomeTeamUUID | string | yes | - | ThreatconnectomeのPTeamのUUID | | no |
| imageRegistryPath | string | yes | - | ビルドしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス | asia-northeast1-docker.pkg.dev/<br>${project_id}/sample | no |
| imageShortName | string | yes | - | ビルドするコンテナイメージの省略名 | nginx | no |
| imageTag | string | yes | - | コンテナイメージのタグ名 | v1.0.0 | no |


### Results Parameters

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| threatconnectome | threatconnectomeのTaskを実行し、コンテナイメージのSBOMを出力して、Threatconnectomeにアップロードします。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| threatconnectome | threatconnectome | - | 指定のコンテナレジストリのイメージのSBOMを出力して、Threatconnectomeにアップロードします。 |
## Usage
``` yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pipeline/scan:threatconnectomeGcp
```

## Code
[imageScan:threatconnectome](../../pipeline/scan/threatconnectomeGcp.cue)
