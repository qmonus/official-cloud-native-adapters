# Resolve IP Address Sample Adapter
Qmonus Value Streamを用いて、**事前にデプロイされた**Kubernetes Serviceリソース(type: loadbalancer)のグローバルIPを取得し、ResultsとしてQmonus Value Stream 上に保持します。AssemblyLineでこのResultsを指定することで、GUI上でグローバル IPはAssemblyLine Results として確認することができます。

## Module
- Module: `qmonus.net/adapter/official`
- Import path `qmonus.net/adapter/official/pipeline/sample:resolveIPAddress`

## Level
Sample: サンプル実装

## Prerequisites / Constraints

### Prerequisites
* 本Adapterによって生成されるPipeline/Taskが実行される前に、事前にKubernetes Serviceリソース(type: loadbalancer)をデプロイしておく必要があります。

## Platform
General / Platform Free

## Parameters

### Adapter Options
None

### Parameters
| Parameter Name | Type | Required | Default | Description | Example | Auto Binding |
| --- | --- | --- | --- | --- | --- | --- |
| appName | string | yes | - | QVSにおけるApplication名 | nginx | yes | 
| k8sNamespace | string | yes | - | 対象となるServiceリソースが存在するnamepsace | | yes | 
| kubeconfigSecretName | string | yes | - | QVSにおけるDeploymentの作成時に指定したkubeconfigを保管しているk8s Secret名 | | yes |

### Results Parameters
| Parameter Name | Type | Description | Example |
| --- | --- | --- | --- |
| ipAddress  | string | 取得したServiceリソース(type: loadbalancer)のグローバルIPアドレス | xx.xx.xx.xx |

## Resources
以下の Tekton Pipeline/Task リソースを含むマニフェストが作成されます。

### Pipeline
| Resource ID | Description |
| --- | --- |
| resolve-ip-address-after-deploy  | resolve-ip-addressのTaskを実行し、**事前にデプロイされた**Serviceリソース(type: loadbalancer)のグローバルIPアドレスを取得します。 |

### Task
| Resource ID | Pipeline | runAfter | Description |
| --- | --- | --- | --- |
| resolve-ip-address | resolve-ip-address-after-deploy | - | Serviceリソース(type: loadbalancer)のグローバルIPアドレスを取得します。 |

## Usage
``` yaml
designPatterns: 
　- pattern: qmonus.net/adapter/official/pipeline/deploy:simple # 事前にServiceリソースをデプロイするためのCI/CD Adpterを共に宣言することで、本Adapterが機能する
  - pattern: qmonus.net/adapter/official/pipeline/sample:resolveIPAddress
```

## Code
[sample:resolveIPAddress](../../pipeline/sample/resolveIPAddress.cue)
