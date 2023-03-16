# Azure Image Promotion Adapter
Qmonus Value Streamを用いて、コンテナレジストリに保存されたイメージを別のコンテナレジストリにコピーするAdapterです。検証環境から商用環境へイメージをコピーするためにご利用いただけます。

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/pipeline/utils:imagePromoteAzure`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints

### Prerequisites
コンテナレジストリとしてAzure Container Registryを使用することが前提になります。

Qmonus Value Streamへ認証情報を登録するサービスプリンシパルの権限として、以下が必要になります。
* コピー元のレジストリに対する権限:
  * Azure Container Registry: 組み込みロールの場合は`AcrPull`

* コピー先のレジストリに対する権限:
  * Azure Container Registry: 組み込みロールの場合は`Contributor (共同作成者)`
 
## Platform
Azure Container Registry, Microsoft Azure
## Parameters

### Adapter Options
| Parameter Name  | Type | Required | Default | Description | Example |
| --- | --- | --- | --- | --- | --- |
| image | string | no | "" | 生成されるTaskのimage-promoteに接頭語を付与します。また、[Results Parameters](#results-parameters) の変数名にも同様に接頭語を与えます。複数のイメージを指定してValue Streamを実行する際、本パラメータにコピーするイメージ名を指定することでTaskを区別することができます。| nginx |


### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| azServicePrincipalSecretName | string | yes | - | Azure サービスプリンシパルのjsonキーを保管しているk8s Secret名 | | no |
| azureTenantId   | string | yes | - | コピー先のコンテナレジストリが属するテナントのID| xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | no |
| containerRegistry  | string | yes | - | コピー元のコンテナレジストリの完全修飾名 | ${acr_name}.azurecr.io　| no |
| imageNameFrom | string | yes | - | コピー元のイメージのフルパス | ${acr_name}.azurecr.io/<br>sample/nginx:buildcache | no |
| imageRegistryPath | string | no | - | コピーしたイメージをプッシュするコンテナレジストリのイメージ名を含まないパス | ${acr_name}.azurecr.io/sample | no |
| imageShortName | string | yes | - | コピーしたコンテナイメージの省略名 | nginx | no |
| imageTag | string | yes | - | コンテナイメージのタグ名 | v1.0.0 | no |

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| imageFullNameTag  | string | コピー後のイメージ名のフルパスにタグ名を加えたもの | ${acr_name}.azurecr.io/<br>sample/nginx:latest |
| imageFullNameDigest  | string | コピー後のイメージ名のフルパスにダイジェスト値を加えたもの | ${acr_name}.azurecr.io/<br>sample/nginx@sha256:xxxxxxxxxxxx |
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
  - pattern: qmonus.net/adapter/official/pipeline/utils:imagePromoteAzure
```

## Code
[utils:imagePromoteAzure](../../pipeline/utils/imagePromoteAzure.cue)
