<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > 機能マトリクス { #compute-instance-feature-matrix }

インスタンスサービスが提供する機能をリージョンと料金プラン観点から整理したドキュメントです。翻訳パイプラインテストのため、表、リスト、コードブロック、ネストされた見出しをすべて含みます。

<a id="feature-overview"></a>
## 機能概要 { #feature-overview }

インスタンスの主要機能は次のとおりです。

- **インスタンス作成**: イメージとタイプを選択して仮想サーバーを作成します。
- **インスタンステンプレート**: よく使う設定をテンプレートとして保存して再利用します。
- **スケジューリング**: 指定した時間にインスタンスを開始または停止します。
- **モニタリング**: CPU、メモリ、ディスク使用量をダッシュボードで確認します。

<a id="feature-by-region"></a>
## リージョン別機能提供状況 { #feature-by-region }

リージョンに応じて提供される機能が異なります。下記の表で確認してください。

| 機能コード | 機能名 | Pangyo | Pyeongchon | Japan |
|---|---|---|---|---|
| INST-CREATE | インスタンス作成 | 提供 | 提供 | 提供 |
| INST-TPL | インスタンステンプレート | 提供 | 提供 | 非提供 |
| INST-SCHED | インスタンススケジューリング | 提供 | 非提供 | 非提供 |
| INST-MON | インスタンスモニタリング | 提供 | 提供 | 提供 |

<a id="feature-by-plan"></a>
### 料金プラン別提供上限 { #feature-by-plan }

料金プランに応じて、作成可能なインスタンス数が異なります。

| 料金プラン | 最大インスタンス数 | 最大ブロックストレージ |
|---|---|---|
| 基本 | 10台 | 1TB |
| 標準 | 50台 | 10TB |
| エンタープライズ | 無制限 | 無制限 |

<a id="feature-api"></a>
## API で機能確認 { #feature-api }

機能提供状況は API でも確認できます。

<a id="feature-api-request"></a>
### リクエスト { #feature-api-request }

下記の例のように機能コードを指定して呼び出します。

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### 応答フィールド

応答本文の主要フィールドは次のとおりです。

- `code`: 機能コード
- `available`: 提供状況 (true/false)
- `regions`: 提供リージョンリスト

<a id="feature-notes"></a>
## 注記事項 { #feature-notes }

機能提供状況は事前告知の後で変更される可能性があります。最新情報はコンソール通知を確認してください。