<!-- machine_translated: true -->

<!-- pre-align:aligned sig=e2epostmaint1 -->

<a id="pm-intro"></a>
## 翻訳PR文書整備サンプル { #pm-intro }

この文書は翻訳PR文書整備(`--post-maint`)を検証するためのフィクスチャです。
ko PRはこの段落のこの1文だけを修正して翻訳を起動させます。

<a id="pm-markup"></a>
## マークアップの欠陥 { #pm-markup }

詳細は[APIガイド](https://docs.example.com/api/)を参照してください。

<a id="pm-stub"></a>
## 本文が空のセクション { #pm-stub }

<!-- TODO: translate body -->

<a id="pm-table"></a>
## 行が欠けた表 { #pm-table }

| 名前 | タイプ | 説明 |
|---|---|---|
| appKey | String | アプリキー |
| secretKey | String | シークレットキー |
| region | String | リージョンコード |

<a id="pm-jinja"></a>
## テンプレートタグ { #pm-jinja }

{% if "gov" in build_flags %}
公共環境ではコンソールのメニュー名が異なります。
{% endif %}

<a id="pm-tail"></a>
## 最後のセクション { #pm-tail }

このセクションはどの整備でもバイト単位で保持される必要があります。
