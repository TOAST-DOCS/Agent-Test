<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロタグ形状コレクション { #sample-macro-shapes }

このドキュメントは、mkdocs-macrosテンプレートタグが翻訳を経てもまったく変わらないかを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ1行を失い、alphaビルドを破損させた事故(2026-09-07)から生じたパターンを1か所に集めました。タグは制御文法なので翻訳対象ではなく、1つでも失われるとペアがずれて `_Macro Syntax Error_` でビルド全体が失敗します。(本文修正テスト: この文章は翻訳再実行時に反映されるべきです。)

<a id="wrapped-paragraph"></a>
### 段落を囲む条件付き { #wrapped-paragraph }

{% if "gov" not in build_flags %}
パブリック環境ではコンソールで直ちに設定できます。この段落は開きタグがすぐ上に付いているため、増分翻訳においてタグと1つのユニットになります。事故が起きたパターンはまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件付き { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` であり、この文章は開きタグと閉じタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを囲む条件付き { #wrapped-example }

{% if "gov" not in build_flags %}
下の例示は条件付きブロック内に `<details>` とコードフェンスが一緒に含まれています。タグ保護とフェンス保護が同じユニット内で重複する場合です。

<details>
<summary>トークン発行リクエスト例示</summary>

```
$ curl -X POST \
  -H 'Content-Type: application/json' \
  $[ portal_url ]$/v2/tokens
```
</details>

{% endif %}
<a id="variable-table"></a>
### 表内の変数置換 { #variable-table }

| 区分 | アドレス | 補足 |
|---|---|---|
| コンソール | `$[ portal_url ]$` | 環境に応じて異なります<br>テーブル行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョンパスが付加されます |

<a id="branch-both-ways"></a>
### 両側分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府ネットワーク環境では担当者に発行手続きを問い合わせる必要があります。
{% else %}
パブリック環境ではコンソールから直接発行できます。
{% endif %}