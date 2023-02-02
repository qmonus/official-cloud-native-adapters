# Helm: External Secrets Operator Adapter
Kubernetesアプリケーション向けのパッケージマネージャであるHelmを用いた、Kubernetesへの[External Secrets Operator](https://external-secrets.io/)（以下、ESO）のインストール用Cloud Native Adapterです。ESOをインストールすることで、External Secretリソースを使用してクラウドプロバイダーが提供する機密情報管理サービスに格納している値とKubernetesのSecretリソースの値を連携することが可能です。

ESOの[Custom Resource Definition](https://github.com/external-secrets/external-secrets/blob/main/deploy/crds/bundle.yaml)については本Cloud Native Adapterではインストールせず、別途事前に手動でApplyが行われている想定です。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/kubernetes/secrets/eso`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints
### Prerequisites
* ESOの[CRD](https://github.com/external-secrets/external-secrets/blob/main/deploy/crds/bundle.yaml)の任意のバージョンをKubernetesクラスタへApplyしてください。

### Constraints
* 使用するKubernetes環境はインターネットに接続できることが前提となります。
* 事前に用意したCRDのみのESOのバージョンと、インストールするCRDを除いたESOのバージョン（`version`）を合わせてください。
* 使用するバージョンは、`v0.5.0` 以降のものを使用してください。

## Platform
Kubernetes

## Parameters
| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| version | string | yes | - | インストールするESO（CRDを除く）のバージョン |
| k8sNamespace | string | no | qmonus-system | ESOがインストールされるNamespace |

## Resources
ESOインストールによって作成されるリソース一覧については、以下のリンクを参照してご利用されるバージョンを選択してください。

https://artifacthub.io/packages/helm/external-secrets-operator/external-secrets?modal=template

## Usage
```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/kubernetes/secrets/eso
    params:
      version: "0.5.1"
      k8sNamespace: $(params.k8sNamespace)
```

## Code
[secrets-eso](../../kubernetes/secrets/eso/)
