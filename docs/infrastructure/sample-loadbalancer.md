# Sample Load Balancer Adapter

クラウドプロバイダーが提供するManaged Kubernetes上で動作するアプリケーション公開用のCloud Native Adapterです。
クラウドプロバイダーのロードバランサーを使用して、Serviceを外部に公開します。

## Module
- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/kubernetes/sample:loadbalancer`

## Level
Sample: サンプル実装

## Prerequisites / Constraints
### Constraints
* KubernetesにおけるDeployment相当に関しては、別のCloud Native Adapterと組み合わせてください。
* 公開できるポートは1つだけです。

## Platform
Kubernetes

## Parameters
| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| appName | string | yes | - | デプロイするアプリケーション名 |
| k8sNamespace | string | yes | - | アプリケーションをデプロイする対象のNamespace |
| port | string | yes | - | アプリケーションが利用するポート番号 |
## Resources
| Resource ID | Provider | API version | Kind | Description |
| --- | --- | --- | --- | -- |
| service | kubernetes | v1 | Service | クラウドプロバイダーのロードバランサーを使用して、Serviceを外部に公開します。 |

## Usage
```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/kubernetes/sample:loadbalancer
    params:
      appName: simple-test-app
      k8sNamespace: $(params.k8sNamespace)
      port: $(params.port)
```

## Code
[sample-loadbalancer](../../kubernetes/sample/loadbalancer.cue)
