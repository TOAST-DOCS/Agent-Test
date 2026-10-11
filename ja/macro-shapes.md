<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0c594ab22164 -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロ タグ パターン集 { #sample-macro-shapes }

このドキュメントは、mkdocs-macros テンプレート タグが翻訳を経ても1文字も変わらないことを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ1行を失いalphaビルドを破壊した障害(2026-09-07)から出たパターンをまとめました。タグは制御文法なので翻訳対象ではなく、1つでも喪失すると対が合致せず `_Macro Syntax Error_` でビルド全体が失敗します。(本文修正テスト: この文は翻訳の再実行時に反映されなければなりません。)

<a id="wrapped-paragraph"></a>
### 文段を囲む条件分岐 { #wrapped-paragraph }

{% if "gov" not in build_flags %}
公用環境ではコンソールから直接設定できます。この段落は、開くタグがすぐ上に付いているため、増分翻訳でタグと1つのユニットになります。障害が発生したパターンが正にこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件分岐 { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` であり、この文は開くタグと閉じるタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを囲む条件分岐 { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例は、条件分岐ブロック内に `<details>` とコード フェンスが一緒に入っています。タグ保護とフェンス保護が同じユニットで重なる場合です。

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
| コンソール | `$[ portal_url ]$` | 環境によって異なります<br>表行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョン パスが付きます |

<a id="branch-both-ways"></a>
### 両側分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府網環境では担当者に発行手続きについて問い合わせる必要があります。
{% else %}
公用環境ではコンソールから直接発行できます。
{% endif %}