# GKE Cluster Secret Store Adapter
Google Kubernetes Engine（以下、GKE）への [Cluster Secret Store](https://external-secrets.io/v0.5.3/api-clustersecretstore/) Apply用のCloud Native Adapterです。

[Helm: External Secrets Operator Adapter](secrets-eso.md)でインストールしたExternal Secrets OperatorからExternal Secretリソースを使用するには、クラウドプロバイダーへの認証情報を提供するCluster Secret Storeが必要となります。
本Cloud Native Adapterでは、GCP上で設定されたWorkload Identityと連携するKubernetes Service Account（以下、KSA）と、KSAを指定してESにGoogle Secret Managerへのアクセス権限を渡すCluster Secret Storeを提供します。

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/kubernetes/secrets/gke/clustersecretstore`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints
### Prerequisites
1. [Helm: External Secrets Operator Adapter](secrets-eso.md) を利用して、External Secrets OperatorをGKEへインストールしてください。
2. [GKEのWorkload Identityを有効](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity?hl=ja#enable)にしてください。
3. KSAと紐づけるGoogle Service Account（以下、GSA）の作成とIAMによるWorkloadIdentityの設定を行ってください。
   * GSAの作成
     * GSAを任意の名前で作成してください。GSAの名前は、[Parameters](#parameters)の`gsaName`として指定する必要があります。default値を使用する場合はGSAの名前を"external-secrets-operator"として作成してください。
     * GSAにSecret Managerへの読み取り権限として、`roles/secretmanager.secretAccessor` を付与してください。
   * Workload Identityの設定
     * KSAにGSAのポリシーをバインディング、および`roles/iam.serviceAccountTokenCreator`を付与してください。
     ```bash
     # gcloudコマンド例（Secret Managerが存在するプロジェクトで実行してください）
     gcloud iam service-accounts add-iam-policy-binding ${gsaName}@${gsaGcpProject}.iam.gserviceaccount.com --role roles/iam.serviceAccountTokenCreator --member "serviceAccount:${k8sClusterGcpProject}.svc.id.goog[${ksaNamespace}/${appName}]"
     ```
     また、変数として記載している`${gsaGcpProject}`、`${k8sClusterGcpProject}`、`${ksaNamespace}`、`${appName}` は、それぞれ[Parameters](#parameters)の`gsaGcpProject`（defaultでは`smGcpProject`と一致）、`k8sClusterGcpProject`（defaultでは`smGcpProject`と一致）、`ksaNamespace`（defaultでは"qmonus-system"） 、`appName`（defaultでは"gcp-secret-manager"）と一致させる必要があります。

## Platform
Kubernetes, Google Cloud

## Parameters
| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| appName | string | no | gcp-secret-manager | KSAおよびCluster Secret Storeのリソース名 |
| smGcpProject | string | yes | - | Secret Managerが存在するGCPプロジェクトID |
| gsaGcpProject | string | no | ${smGcpProject} | GSAが存在するGCPプロジェクトID |
| k8sClusterGcpProject | string | no | ${smGcpProject} | GKEクラスターが存在するGCPプロジェクトID |
| gsaName | string | no | external-secrets-operator | GSA名 |
| ksaNamespace | string | no | qmonus-system | KSAをデプロイするNamespace |
| k8sClusterLocation | string | yes | - | GKEクラスターが存在するリージョン名 |
| k8sClusterName | string | yes | - | GKEクラスター名 |

## Resources
| Resource ID | Provider | API version | Kind | Description |
| --- | --- | --- | --- | --- |
| serviceaccount | kubernetes	 | v1 | Service | Google Service Accountを指定して権限を借用します |
| clustersecretstore | kubernetes	 | external-secrets.io/v1beta1 | ClusterSecretStore | Workload IdentityによるGCPアクセス権限が付与されたKubernetes Service Accountを指定してGCPへの認証を行います |

## Usage
```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/kubernetes/secrets/gke/clustersecretstore
    params:
      smGcpProject:       $(params.smGcpProject)
      k8sClusterName:     $(params.k8sClusterName)
      k8sClusterLocation: $(params.k8sClusterLocation)
```

## Code
[gke-clustersecretstore](../../kubernetes/secrets/gke/clustersecretstore/)
