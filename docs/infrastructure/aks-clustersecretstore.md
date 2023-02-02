# AKS Cluster Secret Store Adapter
Azure Kubernetes Service（以下、AKS）への [Cluster Secret Store](https://external-secrets.io/latest/api-clustersecretstore/) Apply用のCloud Native Adapterです。

[Helm: External Secrets Operator Adapter](secrets-eso.md)でインストールしたExternal Secrets OperatorからExternal Secretリソースを使用するには、クラウドプロバイダーへの認証情報を提供するCluster Secret Storeが必要となります。
本Cloud Native Adapterでは、Azure AD Workload Identityで連携するKubernetes Service Accountを指定して、External SecretにAzure Key Vaultへのアクセス権限を渡すCluster Secret Storeを提供します。

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/kubernetes/secrets/aks/clustersecretstore`

## Level
Best Practice: ベストプラクティスにもとづく実装

## Prerequisites / Constraints
### Prerequisites
1. [Helm: External Secrets Operator Adapter](secrets-eso.md) を利用して、External Secrets OperatorをAKSへインストールしてください。
2. API サーバーが公開署名キーを検出できるようにするために、プロバイダーの OIDC Issuer URLを有効にします。
   * [Azure CLIのバージョンを最新化](https://docs.microsoft.com/ja-jp/cli/azure/update-azure-cli)してください。
   * [EnableOIDCIssuerPreview 機能フラグの登録](https://docs.microsoft.com/ja-jp/azure/aks/cluster-configuration#register-the-enableoidcissuerpreview-feature-flag)を行ってください。
   * [aks-preview CLI 拡張機能のインストール](https://docs.microsoft.com/ja-jp/azure/aks/cluster-configuration#install-the-aks-preview-cli-extension)を行ってください。
   * [OIDC Issuer を備えた AKS クラスターを更新](https://docs.microsoft.com/ja-jp/azure/aks/cluster-configuration#update-an-aks-cluster-with-oidc-issuer)してください。
   * 以下のコマンドから、OIDC発行者URLを取得します。ここで、`${myAksName}`はAKSクラスター名、`${myResourceGroup}`はAKSクラスターが所属するリソースグループです。
   ```bash
   $ az aks show -n ${myAksName} -g ${myResourceGroup} --query "oidcIssuerProfile.issuerUrl" -otsv

   ${oidcIssuerUrl}
   ```
3. Azure Active Directoryのアプリケーションを作成し、Azure Key Vaultへの権限を付与します。
   * [キーコンテナを作成](https://docs.microsoft.com/ja-jp/azure/key-vault/general/quick-create-portal#create-a-vault) してください。
   * [Azure AD Workload Identity CLI(azwi)](https://github.com/Azure/azure-workload-identity/releases/latest) をインストールしてください。
   * 以下のコマンドから、Azure Active Directoryアプリケーションを作成し、Key Vaultへのアクセス権限を付与します。ここで、`${applicationName}`は、登録するアプリケーションの名前です。`${azureKeyContainerName}`はキーコンテナ名で、[Parameters](#parameters)で指定するものです。
   ```bash
   $ azwi serviceaccount create phase app --aad-application-name ${applicationName}
   $ export applicationCliendId="$(az ad sp list --display-name ${applicationName} --query '[0].appId' -otsv)"
   $ az keyvault set-policy --name ${azureKeyContainerName} --secret-permissions get --spn ${applicationCliendId}
   ```
4. Kubernetes Service Account（以下、KSA）を作成し、Azure AD Workload Identityを使用してAzure Key Vaultへのアクセス権限を付与します。
   * KSAを以下のコマンドから作成してください。ここで、`${ksaName}`はKSA名、`${ksaNamespace}`はKSAが属するnamespaceとしてそれぞれ[Parameters](#parameters)で指定するものです。default値を使用する場合は、それぞれ"azure-key-vault", "qmonus-system"として指定してください。
   ```bash
   # KSAが所属するnamespaceを事前に作成しておく
   $ kubectl create ns ${ksaNamespace}
   $ azwi serviceaccount create phase sa --aad-application-name ${applicationName} --service-account-namespace ${ksaNamespace} --service-account-name ${ksaName}  
   ```
   * 作成したKSAにAzure Key Vaultへのアクセス権限を付与します。
   ```bash
   $ azwi serviceaccount create phase federated-identity --aad-application-name ${applicationName} --service-account-name ${ksaName} --service-account-namespace ${ksaNamespace} --service-account-issuer-url ${oidcIssuerUrl}
   ```   

## Platform
Kubernetes, Microsoft Azure

## Parameters
| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| appName | string | no | azure-key-vault | Cluster Secret Storeのリソース名 |
| azureKeyContainerName | string | yes | - | Azure キーコンテナ名 |
| ksaName | string | no | azure-key-vault | KSA名 |
| ksaNamespace | string | no | qmonus-system | KSAが存在するnamespace |

## Resources
| Resource ID | Provider | API version | Kind | Description |
| --- | --- | --- | --- | --- |
| clustersecretstore | kubernetes | external-secrets.io/v1beta1 | ClusterSecretStore | Azure AD Workload IdentityによるKey Vaultアクセス権限が付与されたKubernetes Service Accountを指定してAzureへの認証を行います |

## Usage
```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/kubernetes/secrets/aks/clustersecretstore
    params:
      azureKeyContainerName:  $(params.azureKeyContainerName)
```

## Code
[aks-clustersecretstore](../../kubernetes/secrets/aks/clustersecretstore/)
