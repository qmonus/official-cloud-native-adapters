# Official Cloud Native Adapter
## internalリポジトリとpublicリポジトリとGoogle Cloud Storage

Official Cloud Native Adapterのリポジトリは[internalリポジトリ](https://github.com/qmonus/official-cloud-native-adapters-internal)と[publicリポジトリ](https://github.com/qmonus/official-cloud-native-adapters)の2つのリポジトリがGitHubに存在します。
また、qvsctlやQmonus Value Streamでダウンロードして利用するために、Google Cloud Storageにもアップロードされています。

### GitHubのinternalリポジトリについて

このリポジトリがinternalリポジトリで、これは開発用のリポジトリとして利用されます。Qmonus Value Streamの開発者はinternalリポジトリを使って開発、PR、レビュー、マージします。基本的にはvs-mvpやqvsctl等の他の開発用リポジトリと同様の使い方となります。

### GitHubのpublicリポジトリについて

ユーザへ公開するリポジトリです。ユーザはgit cloneしたりGitHub上で閲覧できます。閲覧用なので、開発時のPRや開発中のコードは公開されません。また、一部のファイルは公開されません。プロダクトリリース時にAssemblyLineによりinternalリポジトリからtagの名前がついたブランチがpushされた後に手動でmainにマージすることで更新され、手動でリリースノートが更新されます。その他の方法でpublicリポジトリを更新するのは禁止しており、手動でpushできないように設定されています。

### Google Cloud Storage

ユーザがqvsctlを使ってダウンロードして利用したり、Qmonus Value Streamがコンパイルして利用するため、Google Cloud Storageにも保存されています。publicリポジトリと同様に一部のファイルは公開されません。また、プロダクトリリース時にAssemblyLineによりinternalリポジトリからファイル転送されて更新されます。

## publicおよびGoogle Cloud Storageへの公開

[リリース手順](https://www.notion.so/nttcom/Cloud-Native-Adapter-deedc76172e7495b8a1ea22c5f054d85)により公開されます。

publicリポジトリとGoogle Cloud Storageには以下のファイルは公開されません。
- README-internal.md
- git/ 
- .gitignore 
- .github/ 
- go.sum 
- pipeline/test/
- test/ 
- .valuestream/

## Official Cloud Native Adapterの試験について

Adapterを新規に作成したり変更した場合、testディレクトリ以下にテストケースやテストの期待値となるファイルを書き、qvsctlを用いて試験してください。qvsctlを使った試験方法の詳細は[qvsctl manifest testのリファレンス](https://docs.valuestream.qmonus.net/spec/qvsctl/manifest-test.html)もしくは[qvsctl pipeline testのリファレンス](https://docs.valuestream.qmonus.net/spec/qvsctl/pipeline-test.html)に書かれています。また、testディレクトリ以下に置くテストケースや期待値となるファイルは、Adapterの実装とtestが1対1で対応するディレクトリ構成となるように配置してください。

## ディレクトリ構成

本リポジトリのディレクトリ構成を示します。

```text
official-cloud-native-adapters/
├── .github # GitHub ActionsによるCI設定
├── .valuestream # AssemblyLineを使って公開するためのQVS config
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
├── pipeline/  # Official CI/CD Adapterの実装
└── test/
    ├── base.cue
    ├── kubernetes/  # Official Infrastructure Adapterの実装のうち、Kubernetes関連のテスト
    └── pipeline/  # Official CI/CD Adapterの実装のテスト
```
