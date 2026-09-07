<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > 機能マトリックス { #compute-instance-feature-matrix }

このドキュメントは、インスタンスサービスが提供する機能をリージョンと料金プランの観点から整理したものです。翻訳パイプラインテストのために、表、リスト、コードブロック、ネストされたheadingをすべて含めています。

<a id="feature-overview"></a>
## 機能概要 { #feature-overview }

インスタンスの主要な機能は次のとおりです。

- **インスタンス作成**: イメージとタイプを選択して、仮想サーバーを作成します。
- **インスタンステンプレート**: 頻繁に使用される設定をテンプレートとして保存して再利用します。
- **スケジューリング**: 指定した時間にインスタンスを開始または停止します。
- **モニタリング**: CPU、メモリ、ディスク使用量をダッシュボードで確認します。

<a id="feature-by-region"></a>
## リージョン別機能提供状況 { #feature-by-region }

リージョンによって提供される機能が異なります。以下の表で確認してください。

| 機能コード | 機能名 | 판교 | 평촌 | 日本 |
|---|---|---|---|---|
| INST-CREATE | インスタンス作成 | 提供 | 提供 | 提供 |
| INST-TPL | インスタンステンプレート | 提供 | 提供 | 未提供 |
| INST-SCHED | インスタンススケジューリング | 提供 | 未提供 | 未提供 |
| INST-MON | インスタンスモニタリング | 提供 | 提供 | 提供 |

<a id="feature-by-plan"></a>
### 料金プランごとの提供限度 { #feature-by-plan }

料金プランに応じて、作成可能なインスタンス台数が異なります。

| 料金プラン | 最大インスタンス台数 | 最大ブロックストレージ |
|---|---|---|
| 基本 | 10台 | 1TB |
| 標準 | 50台 | 10TB |
| エンタープライズ | 無制限 | 無制限 |

<a id="feature-api"></a>
## APIで機能確認 { #feature-api }

機能の提供可否は、APIでも確認できます。

<a id="feature-api-request"></a>
### 照会要求 { #feature-api-request }

以下の例のように、機能コードを指定して呼び出します。

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### 応答フィールド

応答本文の主要フィールドは次のとおりです。

- `code`: 機能コード
- `available`: 提供の可否 (true/false)
- `regions`: 提供リージョン一覧

<a id="feature-notes"></a>
## 参考事項 { #feature-notes }

機能提供の可否は、事前告知の上で変更される場合があります。最新情報はコンソールのお知らせを確認してください。