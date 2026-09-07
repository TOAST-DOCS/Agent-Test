<!-- machine_translated: true -->

<!-- pre-align:aligned sig=af6d5efd1d39 -->

<a id="compute-instance-feature-matrix"></a>
## Compute > Instance > 機能マトリックス { #compute-instance-feature-matrix }

インスタンス サービスが提供する機能をリージョンと料金プランの観点から整理したドキュメントです。翻訳パイプラインテストのため、表、リスト、コードブロック、ネストされたヘッディングをすべて含みます。

<a id="feature-overview"></a>
## 機能概要 { #feature-overview }

インスタンスの主な機能は次のとおりです。

- **インスタンス作成**: イメージとタイプを選択して仮想サーバーを作成します。
- **インスタンステンプレート**: 頻繁に使用する設定をテンプレートとして保存して再利用します。
- **スケジューリング**: 指定した時間にインスタンスを開始または停止します。
- **モニタリング**: CPU、メモリ、ディスク使用量をダッシュボードで確認します。

<a id="feature-by-region"></a>
## リージョン別機能提供の有無 { #feature-by-region }

リージョンによって提供される機能が異なります。以下の表を確認してください。

| 機能コード | 機能名 | パンギョ | ピョンチョン | 日本 |
|---|---|---|---|---|
| INST-CREATE | インスタンス作成 | 提供 | 提供 | 提供 |
| INST-TPL | インスタンステンプレート | 提供 | 提供 | 未提供 |
| INST-SCHED | インスタンススケジューリング | 提供 | 未提供 | 未提供 |
| INST-MON | インスタンスモニタリング | 提供 | 提供 | 提供 |

<a id="feature-by-plan"></a>
### 料金プラン別提供上限 { #feature-by-plan }

料金プランによって作成可能なインスタンス数が異なります。

| 料金プラン | 最大インスタンス数 | 最大ブロックストレージ |
|---|---|---|
| 基本 | 10 | 1TB |
| 標準 | 50 | 10TB |
| エンタープライズ | 無制限 | 無制限 |

<a id="feature-api"></a>
## API で機能を確認 { #feature-api }

機能の提供状況は API でも確認できます。

<a id="feature-api-request"></a>
### 照会リクエスト { #feature-api-request }

以下の例のように機能コードを指定して呼び出します。

```
curl -X GET "https://kr1-api-instance.example.com/v2/features?code=INST-CREATE" \
  -H "X-Auth-Token: {token}"
```

<a id="feature-api-response"></a>
#### レスポンスフィールド

レスポンス本文の主なフィールドは次のとおりです。

- `code`: 機能コード
- `available`: 提供の有無 (true/false)
- `regions`: 提供リージョン一覧

<a id="feature-notes"></a>
## 参考事項 { #feature-notes }

機能の提供状況は事前通知のうえ変更される場合があります。最新情報についてはコンソール通知事項を確認してください。