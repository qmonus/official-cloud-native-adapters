# Simple Deployment

アプリケーションを Kubernetes 上で動作させるための Cloud Native Adapter です。
指定したイメージを利用して、Kubernetes における Deployment を作成します。

## Module

- Module: `qmonus.net/adapter/official`
- Import path: `qmonus.net/adapter/official/adapters/kubernetes/deployment/simple`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Constraints

- コンテナに渡せるパラメータは引数、環境変数、ポート番号、レプリカ数のみです。
- 利用できるコンテナは 1 種類のみです。
- 公開できるポートは 1 つだけです。
- 本 Adapter は、デプロイするための Adapter として [Simple Deploy by Pulumi Yaml Adapter](../../../../docs/cicd/deploy-simpleDeployByPulumiYaml.md) のみに対応しています。

## Platform

Kubernetes

## Parameters

| Parameter Name | Type   | Required | Default | Description                                    |
| -------------- | ------ | -------- | ------- | ---------------------------------------------- |
| appName        | string | yes      | -       | デプロイするアプリケーション名                 |
| k8sNamespace   | string | yes      | -       | アプリケーションをデプロイする対象の Namespace |
| image          | string | yes      | -       | デプロイする Docker Image                      |
| args           | list   | no       | [ ]     | アプリケーションに渡す引数                     |
| env            | list   | no       | [ ]     | アプリケーションが利用する環境変数             |
| port           | string | yes      | -       | アプリケーションが利用するポート番号           |
| replicas       | string | no       | "1"     | 作成する Pod のレプリカ数                      |

## Resources

| Resource ID | Provider   | API version | Kind       | Description                           |
| ----------- | ---------- | ----------- | ---------- | ------------------------------------- |
| deployment  | kubernetes | apps/v1     | Deployment | デプロイする Pod リソースを定義します |

## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/adapters/kubernetes/deployment/simple
    params:
      appName: simple-test-app
      k8sNamespace: $(params.k8sNamespace)
      imageName: $(params.imageName)
      args:
        - '--some'
        - '--options'
      env:
        - name: 'MESSAGE'
          value: 'hello world'
        - name: 'MESSAGE2'
          value: 'hello qmonus'
      port: $(params.port)
      replicas: $(params.replicas)
```

## Code

[simple-deployment](main.cue)
