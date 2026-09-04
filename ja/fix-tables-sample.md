<!-- pre-align:aligned sig=86fc80138a36 -->

<a id="fix-tables-sample"></a>
## 壊れた表の整備サンプル { #fix-tables-sample }

このドキュメントは**壊れた表の整備**(`translate/translate_fix_tables.py`)を検証するためのテストフィクスチャです。
en/ja のコピーには、ko と表が食い違うセクションが意図的に 3 つの形で残されており、整備の実行がそのセクションの
本文だけを ko 基準で作り直し、残りのセクションをバイト単位で保存するかを確認します。

このドキュメントはユーザーガイドのメニュー(`ko/nav.yml`)には登録しません。公開されるドキュメントではなく、パイプラインのフィクスチャです。

<a id="fix-tables-untouched"></a>
## 正常な表があるセクション { #fix-tables-untouched }

このセクションの表は、ko と同じ識別子行で en/ja に翻訳されています。整備の実行後も**バイト単位で同一**でなければなりません。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| tokenId | Header | String | トークン ID |
| appKey | Path | String | アプリキー |
| pageSize | Query | Integer | 1 ページあたりの項目数 |

<a id="fix-tables-missing"></a>
## 表が消えたセクション { #fix-tables-missing }
en/ja の同じセクションには以下のテーブルが存在しません。セクション内のテーブル数が ko と異なるため、メンテナンス実行がこのセクションの本文を ko に基づいて再作成する必要があります。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| clusterId | Body | UUID | クラスター UUID |
| clusterName | Body | String | クラスター名 |
| nodeCount | Body | Integer | ノード数 |

<a id="fix-tables-shifted"></a>
## 最初の列が上書きされたセクション { #fix-tables-shifted }
en/ja の同一セクションのテーブルは、行数と列数は ko と同じですが、最初の列の識別子がフォーマット名で覆われています。ko の識別子行が対応テーブルにないため、再度作成する必要があります。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| flavorId | Body | UUID | インスタンスタイプ UUID |
| imageId | Body | UUID | イメージ UUID |
| keyName | Body | String | キーペア名 |

<a id="fix-tables-rows"></a>
## 行が抜けたセクション { #fix-tables-rows }
en/ja の同じセクションでは、表で識別子行が1つ抜けています。残りの行は正常です。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| volumeId | Body | UUID | ブロックストレージ UUID |
| volumeSize | Body | Integer | サイズ(GB) |
| volumeType | Body | String | ストレージの種類 |

<a id="fix-tables-prose-keys"></a>
## 識別子のない表 { #fix-tables-prose-keys }

**否定対照群です。** この表の最初の列は散文なので識別子行がなく、en/ja の表は行数・列数が同じです。観測できる欠陥がないため、整備の実行はこのセクションに触れてはなりません。

| 項目 | 説明 |
|---|---|
| インスタンスタイプ | 作成するインスタンスの CPU/メモリ仕様 |
| ブロックストレージ | ルートボリュームのサイズ |

### アンカーのない子セクション

**2 つ目の否定対照群です。この heading には `<a id>` アンカーも `{ #id }` 属性も付けないでください。**

下の表は en/ja で識別子行が 1 つ抜けています。しかしこの heading にはアンカーがないため、表は上のセクションの所有として帰属され、再構成の単位はこの heading で切れます。整備の実行は上のセクションを作り直さず、PR 本文に「건너뜀」として報告しなければなりません。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
| metricName | Body | String | 指標名 |
| duration | Body | Integer | 継続時間(分) |

<a id="fix-tables-tail"></a>
## 最後のセクション { #fix-tables-tail }

整備対象の後に来るセクションです。前のセクションが作り直された後も、このセクションはバイト単位で保存されなければなりません。
