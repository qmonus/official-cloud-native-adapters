# Provider MySQL Adapter

MySQLリソースをデプロイするためのProviderを定義するCloud Native Adapterです。

## Module

* Module: `qmonus.net/adapter/official`
* Import path `qmonus.net/adapter/official/pulumi/provider:mysql`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Constraints

* MySQL DB接続に必要なパラメータであるユーザ名とパスワードは、別のAdapterを使用して定義する必要があります。

## Platform

MySQL

## Parameters

| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| providerName | string | no | MysqlProvider | 他のリソースから参照する時のプロバイダー名 | 
| endpoint | string | no | localhost | 接続先のMySQLのエンドポイント | 

## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pulumi/provider:mysql
    params:
      endpoint: $(params.endpoint)
```

## Code

[azure](../../pulumi/provider/mysql.cue)
