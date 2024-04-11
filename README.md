# Official Cloud Native Adapter

## はじめに

Cloud Native Adapterは、[Qmonus Value Stream](https://www.valuestream.qmonus.net/)独自のInfrastructure as Code(IaC)の実装です。Official Cloud Native Adapterは、多くの商用プロダクト開発や運用で得られたベストプラクティスを提供するCloud Native Adapterとなります。

このOfficial Cloud Native Adapterには2種類のカテゴリに分けられ、1つ目はクラウドアーキテクチャを構成するInfrastructure Adapterで、2つ目はアプリケーションの試験・ビルド・デプロイ等のCI/CDパイプラインを構成するCI/CD Adapterです。

Qmonus Value Streamのユーザは、これらのCloud Native Adapterを組み合わせるだけで、複雑で難易度の高いクラウドネイティブなアプリケーションのインフラストラクチャとCI/CDパイプラインを構築できます。

## ディレクトリ構成

本リポジトリのディレクトリ構成を示します。

```text
official-cloud-native-adapters/
├── README.md
├── base/
│   └── base.cue
├── cue.mod/  # adapterで使用されるモジュール
├── docs/  # adapterのドキュメント
├── go.mod
├── helm/
│   └── install/
│       └── main.cue
├── kubernetes/  # Official Infrastructure Adapterの実装のうち、Kubernetes関連
└── pipeline/  # Official CI/CD Adapterの実装
```

## 利用方法

Official Cloud Native Adapterは、Qmonus Value Streamの設定ファイルであるQVS Configにimportして利用します。

QVS Configの記載方法と利用方法については以下のドキュメントをご覧ください。

[QVS Config](https://docs.valuestream.qmonus.net/spec/qvs-config/)

Official Cloud Native Adapterの利用方法の全体像を知るにはチュートリアルをご覧ください。

[チュートリアル](https://docs.valuestream.qmonus.net/tutorials/preparation/)

## ドキュメント

本リポジトリのdocs以下にOfficial Cloud Native Adapterのドキュメントを用意しています。

現在、Official Infrastructure Adapterについて、各Adapter毎にドキュメントを提供しています。Official CI/CD Adapterのドキュメントは近日公開予定です。

ドキュメントの各項目についてご説明します。

**Module**

Adapterは、Moduleとして提供されており、QVS Configにimportして利用します。

import方法は[QVS Configの仕様](https://docs.valuestream.qmonus.net/spec/qvs-config/)をご確認ください。

**Level**

現在、`Best Practice: ベストプラクティスにもとづく実装`もしくは`Sample: サンプル実装`の2つのレベルで提供しています。

Sampleはチュートリアル等において試用目的として作成されていますので、商用サービスでの利用はおすすめ出来ません。商用サービスではBest PracticeレベルのAdapterをご利用ください。

**Prerequisites**

Adapterを利用する前に必要となる作業を示します。

**Constraints**

Adapterを利用する際の制限を示します。

**Platform**

デプロイ先のプラットフォームを記載しています。

現在利用可能なクラウドプラットフォームはGoogle CloudもしくはMicrosoft Azureとなります。また、それぞれのプラットフォームにおけるマネージドKubernetesサービスを利用可能です。
CI/CD Adapter等でプラットフォームを問わずに使用できるものについては General / Platform Free と記載しています。

**Parameters**

Adapterで利用するパラメータ名とその説明をしています。パラメータは、QVS ConfigやAssemblyLineを作成する際にも必要となります。
CI/CD Adapterでは、以下2種類のパラメータについてそれぞれ記載しています。
- Adapter Options: QVS Configで指定するパラメータで、コンパイル時に生成されるワークフローを決定します。
- Parameters: 生成されるTekton Pipeline/Taskで指定されるパラメータを示します。
- Results Parameters: Qmonus Value StreamでTekton Pipeline/Taskを実行した後に、Resultsとして保持するパラメータを示します。Resultsの値は後段のPipelineへ渡すようにAssemblyLineで指定することができます。

**Resources**

Infrastructure Adapter: Platformとなるクラウド環境やマネージドKubernetesサービスに作成されるリソースを示します。  
CI/CD Adapter:  生成される Tekton Pipeline/Task リソースを示します。

**Usage**

QVS ConfigでAdapterを指定する際の記載例を示します。

**Code**

リポジトリ内にあるAdapterの実装コードの場所を示します。

## License

See the LICENSE file for license rights and limitations (MIT).


&copy; NTT Communications 2024
