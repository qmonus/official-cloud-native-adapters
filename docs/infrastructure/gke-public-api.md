# GKE Public API Adapter

Google Kubernetes Engineで動作するAPIアプリケーション公開用のCloud Native Adapterです。
アプリケーションをGCE Ingressを用いてセキュアに外部に公開します。
* Cloud ArmorのWAF機能を用いて外部からの攻撃を防ぎます。
* SSLポリシーを設定することにより不要な暗号スイートを無効化できます。
* マネージドTLS証明書を利用することで煩雑な証明書の更新が自動化されます。

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/kubernetes/gke/publicapi`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints
### Prerequisites
1. 以下のGCPリソースをあらかじめ作成してください。
    * 予約済みの外部静的IPアドレス
      * Ingressで利用します
    * Cloud Armorのセキュリティポリシー
      * BackendConfigで利用します
    * SSLポリシー
      * FrontendConfigで利用します
      * SSLポリシーを利用しない場合は不要です

1. アプリケーション公開用のドメインを用意し、上記の外部静的IPアドレスへDNSレコードを設定してください。

### Constraints
* KubernetesにおけるDeployment相当に関しては、別のCloud Native Adapterと組み合わせてください。
* 公開できるポートは1つだけです。

## Platform
Kubernetes, Google Cloud

## Parameters
| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| appName | string | yes | - | デプロイするアプリケーション名 |
| k8sNamespace | string | yes | - | アプリケーションをデプロイする対象のNamespace |
| port | string | yes | - | アプリケーションが利用するポート番号 |
| domainName | string | yes | - | アプリケーションが利用するドメイン名 |
| gcpExternalAddressName | string | yes | - | 予約済み外部静的IPアドレスのリソース名 |
| gcpSecurityPolicyName | string | yes | - | 作成済みのCloud Armorのセキュリティポリシー名 |
| gcpSslPolicyName | string | no | "" | 作成済みのSSLポリシー名 |

## Resources
| Resource ID | Provider | API version | Kind | Description |
| --- | --- | --- | --- | --- |
| backendconfig | kubernetes | cloud.google.com/v1 | BackendConfig | セキュリティポリシーやヘルスチェックの設定を定義します |
| service | kubernetes | v1 | Service | 各Node上で、静的なポートでServiceを公開します |
| frontendconfig | kubernetes | networking.gke.io/v1beta1 | FrontendConfig | SSLポリシーの設定を定義します |
| ingress | kubernetes | networking.k8s.io/v1 | Ingress | Serviceに対する外部からのアクセスを管理します |
| managedcertificate | kubernetes | networking.gke.io/v1 | ManagedCertificate | Ingressリソースで利用するマネージドSSL証明書を定義します |

## Usage
```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/kubernetes/deployment/simple
    params:
      appName: public-api-test-app
      k8sNamespace: $(params.k8sNamespace)
      imageName: $(params.imageName)
      port: $(params.port)
      replicas: $(params.replicas)
  - pattern: qmonus.net/adapter/official/kubernetes/gke/publicapi
    params:
      appName: public-api-test-app
      k8sNamespace: $(params.k8sNamespace)
      port: $(params.port)
      domainName: $(params.domainName)
      gcpExternalAddressName: $(params.gcpExternalAddressName)
      gcpSecurityPolicyName: $(params.gcpSecurityPolicyName)
      gcpSslPolicyName: $(params.gcpSslPolicyName)
```

## Code
[gke-public-api](../../kubernetes/gke/publicapi/)
