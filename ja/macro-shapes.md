<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロタグの形状コレクション { #sample-macro-shapes }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳を経ても1文字も変わらないかを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ1行を失い、alpha ビルドを破壊した事故(2026-09-07)から生まれた形状を1か所に集めました。タグは制御文法であるため翻訳対象ではなく、1つでも失われるとペアがずれて `_Macro Syntax Error_` でビルド全体が失敗します。(本文修正テスト: この文は翻訳再実行時に反映される必要があります。)

<a id="wrapped-paragraph"></a>
### 段落を囲む条件 { #wrapped-paragraph }

{% if "gov" not in build_flags %}
パブリック環境ではコンソールから直接設定できます。この段落は開きタグがすぐ上に付いているため、増分翻訳ではタグと1つのユニットになります。トラブルが起こった形状がまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件 { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` であり、この文は開きタグと閉じタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを囲む条件 { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例は条件ブロック内に `<details>` とコードフェンスが一緒に入っています。タグ保護とフェンス保護が同じユニット内で重なる場合です。

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

| 区分 | アドレス | 備考 |
|---|---|---|
| コンソール | `$[ portal_url ]$` | 環境により異なります<br>表の行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョンパスが付加されます |

<a id="branch-both-ways"></a>
### 双方向分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府網環境では、担当者に発行手順についてお問い合わせください。
{% else %}
パブリック環境ではコンソールから直接発行できます。
{% endif %}