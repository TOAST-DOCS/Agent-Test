<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロタグパターン集 { #sample-macro-shapes }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳を通じても変わらないかを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ1行を失い、alpha ビルドを破壊した事故(2026-09-07)から生まれたパターンを1つの場所に集めました。タグは制御構文であり翻訳対象ではなく、1つでも失われるとペアが崩れ、`_Macro Syntax Error_` でビルド全体が失敗します。(本文修正テスト: この文は翻訳再実行時に反映される必要があります。)

<a id="wrapped-paragraph"></a>
### 段落を包んだ条件付き { #wrapped-paragraph }

{% if "gov" not in build_flags %}
公用環境では、コンソールから直接設定できます。この段落は開始タグが直上に付いているため、増分翻訳でタグと1つのユニットになります。事故が起きたパターンが正確にこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件付き { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` であり、この文は開始タグと終了タグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例ブロックを包んだ条件付き { #wrapped-example }

{% if "gov" not in build_flags %}
下の例は条件付きブロック内に `<details>` とコードフェンスが一緒に含まれています。タグ保護とフェンス保護が同じユニットで重複するケースです。

<details>
<summary>トークン発行リクエスト例</summary>

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
| コンソール | `$[ portal_url ]$` | 環境に応じて異なります<br>表行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョンパスが付きます |

<a id="branch-both-ways"></a>
### 両分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府ネットワーク環境では、担当者に発行手続きを問い合わせる必要があります。
{% else %}
公用環境では、コンソールから直接発行できます。
{% endif %}