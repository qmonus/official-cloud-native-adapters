# Provider Azure Adapter

AzureリソースをデプロイするためのProviderを定義するCloud Native Adapterです。

## Module

* Module: `qmonus.net/adapter/official`
* Import path `qmonus.net/adapter/official/pulumi/provider:azure`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

## Platform

Azure

## Parameters

| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| providerName | string | no | AzureProvider | 他のリソースから参照する時のプロバイダー名 | 


## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pulumi/provider:azure
```

## Code

[azure](../../pulumi/provider/azure.cue)