<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロ タグ の形状 一覧 { #sample-macro-shapes }

このドキュメントは、mkdocs-macros テンプレート タグが翻訳を通しても 1 文字も変わらないかを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ 1 行を失い、alpha ビルドを破壊した事故 (2026-09-07) で生じた形状をここに集めました。タグは制御構文なので翻訳対象ではなく、1 つでも失われるとペアがずれ `_Macro Syntax Error_` でビルド全体が失敗します。(本文修正テスト: この文章は翻訳再実行時に反映されるべきです。)

<a id="wrapped-paragraph"></a>
### 段落をラップする条件付き { #wrapped-paragraph }

{% if "gov" not in build_flags %}
公用環境では、コンソールから直接設定できます。この段落は、開始タグがすぐ上に付いており、増分翻訳でタグと 1 ユニットになります。障害が発生したケースがまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1 行内の条件付き { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` であり、この文章は開始タグと終了タグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例ブロックをラップする条件付き { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例は、条件付きブロック内に `<details>` とコードフェンスが一緒に入っています。タグ保護とフェンス保護が同じユニットで重なるケースです。

<details>
<summary>トークン発行要求の例</summary>

```
$ curl -X POST \
  -H 'Content-Type: application/json' \
  $[ portal_url ]$/v2/tokens
```
</details>

{% endif %}
<a id="variable-table"></a>
### 表内の変数置換 { #variable-table }

| 分類 | アドレス | 備考 |
|---|---|---|
| コンソール | `$[ portal_url ]$` | 環境により異なります。<br>表行内でも置換されます。 |
| API | `$[ portal_url ]$/v2` | バージョンパスが付きます。 |

<a id="branch-both-ways"></a>
### 両側分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府ネットワーク環境では、担当者に発行手順についてお問い合わせする必要があります。
{% else %}
公用環境では、コンソールから直接発行できます。
{% endif %}