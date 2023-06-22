# Provider MySQL Adapter

MySQLリソースをデプロイするためのProviderを定義するCloud Native Adapterです。

## Module

* Module: `qmonus.net/adapter/official`
* Import path `qmonus.net/adapter/official/pulumi/provider:mysql`

## Level

Sample: サンプル実装

## Prerequisites / Constraints

### Constraints

* MySQL接続用のユーザアカウントのパスワードは固定値となっています。

## Platform

MySQL

## Parameters

| Parameter Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| providerName | string | no | MysqlProvider | 他のリソースから参照する時のプロバイダー名 | 
| endpoint | string | no | localhost | 接続先のMySQLのエンドポイント | 
| username | string | no | adminuser | MySQLに接続するためのユーザアカウント名 | 

## Usage

```yaml
designPatterns:
  - pattern: qmonus.net/adapter/official/pulumi/provider:mysql
    params:
      endpoint: $(params.endpoint)
      username: $(params.username)
```

## Code

[azure](../../pulumi/provider/mysql.cue)
