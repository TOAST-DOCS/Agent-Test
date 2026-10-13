<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロ タグ形状集 { #sample-macro-shapes }

このドキュメントは、mkdocs-macros テンプレート タグが翻訳を経ても一文字も変わらないことを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ一行を失い、alpha ビルドを壊す事故（2026-09-07）から出た形状をひとところに集めました。タグは制御文法なので翻訳対象ではなく、ひとつでも喪失すると対が誤ってしまい `_Macro Syntax Error_` でビルド全体が失敗します。（本文修正テスト：この文は翻訳再実行時に反映されるべきです。）

<a id="wrapped-paragraph"></a>
### 段落を包む条件分岐 { #wrapped-paragraph }

{% if "gov" not in build_flags %}
公開環境ではコンソールからすぐに設定できます。この段落は開くタグがすぐ上に付いているため、増分翻訳ではタグと一つのユニットになります。事故が起きた形状がまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 一行内の条件分岐 { #inline-condition }

{% if "gov" not in build_flags %}ポータル アドレスは `$[ portal_url ]$` であり、この文は開くタグと閉じるタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを包む条件分岐 { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例示は条件分岐ブロック内に `<details>` とコード フェンスが一緒に入っています。タグ保護とフェンス保護が同じユニット内で重なる場合です。

<details>
<summary>トークン 発行リクエスト 例示</summary>

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
| API | `$[ portal_url ]$/v2` | バージョン パスが付きます |

<a id="branch-both-ways"></a>
### 両側分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府網環境では担当者に発行手続きを問い合わせる必要があります。
{% else %}
公開環境ではコンソールから直接発行できます。
{% endif %}
