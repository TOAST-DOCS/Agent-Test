<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロタグ例集 { #sample-macro-shapes }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳を経てもまったく変わらないことを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ 1 行を失い alpha ビルドを破断した事故（2026-09-07）から出た形状をひとところに集めました。タグは制御構文であるため翻訳対象ではなく、1 つでも喪失されるとペアが崩れ、`_Macro Syntax Error_` でビルド全体が失敗します。(本文修正テスト: この文は翻訳再実行時に反映される必要があります。)

<a id="wrapped-paragraph"></a>
### 段落をラップした条件付き { #wrapped-paragraph }

{% if "gov" not in build_flags %}
公用環境ではコンソールで直接設定できます。この段落は、開くタグがすぐ上に付いているため、増分翻訳ではタグと 1 つのユニットになります。事故が発生した形状がまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1 行内の条件付き { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` であり、この文は開くタグと閉じるタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例ブロックをラップした条件付き { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例は、条件付きブロック内に `<details>` とコードフェンスが含まれています。タグ保護とフェンス保護が同じユニットで重なるケースです。

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
| コンソール | `$[ portal_url ]$` | 環境に応じて異なります<br>テーブル行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョンパスが付与されます |

<a id="branch-both-ways"></a>
### 両側分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府ネットワーク環境では担当者に発行手続きを問い合わせる必要があります。
{% else %}
公用環境ではコンソールから直接発行できます。
{% endif %}