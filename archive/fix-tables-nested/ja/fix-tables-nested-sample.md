<a id="fix-tables-nested-sample"></a>
## リスト内の表の整備サンプル { #fix-tables-nested-sample }

この文書は、**壊れた表の整備**がリスト項目内にインデントされた表を修正するときにインデントを守るかを検証するテストフィクスチャです。
en/jaのコピーにはkoと最初の列の識別子が異なる表があり、整備の実行後も表がリスト項目内に残る必要があります。

この文書はユーザーガイドのメニューに登録しません。

<a id="fix-tables-nested-list"></a>
## リスト内の表 { #fix-tables-nested-list }

ログタイプごとに次のフィールドが追加されます。

- **学習ログフィールド**

    | 名前 | 説明 |
    | --- | --- |
    | trainingId | 学習ID |

- **エンドポイントログフィールド**

    | 名前 | 説明 |
    | --- | --- |
    | endpointId | エンドポイントID |

- **エンドポイントログフィールド**

    | 名前 | 説明 |
    | --- | --- |
    | endpointId | エンドポイントID |
    | endpointStageId | エンドポイントステージID |

<a id="fix-tables-nested-deep"></a>
## 2段階のリスト内の表 { #fix-tables-nested-deep }

1. リクエスト本文を作成します。
    - **必須フィールド**

        | 名前 | 形式 | 説明 |
        | --- | --- | --- |
        | UUID | UUID | クラスタUUID |
        | Integer | Integer | ノード数 |

2. リクエストを送信します。

<a id="fix-tables-nested-top"></a>
## インデントされていない表 { #fix-tables-nested-top }

このセクションの表はリストの外にあります。整備後も0列目にある必要があります。

| 名前 | 形式 | 説明 |
| --- | --- | --- |
| String | String | リージョンID |
| String | String | アベイラビリティゾーンID |

<a id="fix-tables-nested-untouched"></a>
## 正しいリスト内の表 { #fix-tables-nested-untouched }

- **レスポンスフィールド**

    | 名前 | 説明 |
    | --- | --- |
    | jobId | ジョブID |
    | jobName | ジョブ名 |
