<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロ タグ のパターン集 { #sample-macro-shapes }

このドキュメントは、mkdocs-macrosテンプレートタグが翻訳を通しても1文字も変わらないかを検証するためのフィクスチャです。Storage-Object-Storageの`ja/acl-guide.md`がタグ1行を失い、alpha ビルドを破壊したインシデント(2026-09-07)から発生したパターンを1つの場所に集めました。タグは制御文法なので翻訳対象ではなく、1つでも欠落すると対が合わなくなり、`_Macro Syntax Error_`でビルド全体が失敗します。(本文修正テスト: この文は翻訳再実行時に反映されるべきです。)

<a id="wrapped-paragraph"></a>
### 段落を囲む条件付き { #wrapped-paragraph }

{% if "gov" not in build_flags %}
パブリック環境ではコンソールで直接設定できます。この段落は開始タグがすぐ上に付いているため、増分翻訳ではタグと1つのユニットになります。このインシデントのパターンが、まさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件付き { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは`$[ portal_url ]$`であり、この文は開始タグと終了タグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを囲む条件付き { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例は条件付きブロック内に`<details>`とコードフェンスが一緒に含まれています。タグ保護とフェンス保護が同じユニット内で重なるケースです。

<details>
<summary>トークン発行リクエストの例</summary>

```
$ curl -X POST \
  -H 'Content-Type: application/json' \
  $[ portal_url ]$/v2/tokens
```
</details>

{% endif %}
<a id="variable-table"></a>
### 表内の変数置換 { #variable-table }

| 区分 | アドレス | 備考 |
|---|---|---|
| コンソール | `$[ portal_url ]$` | 環境によって異なります<br>表の行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョンパスが付きます |

<a id="branch-both-ways"></a>
### 両側分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府ネットワーク環境では、担当者に発行手順をお問い合わせする必要があります。
{% else %}
パブリック環境ではコンソールで直接発行できます。
{% endif %}