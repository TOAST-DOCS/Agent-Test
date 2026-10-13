<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロ タグの形状集 { #sample-macro-shapes }

このドキュメントは、mkdocs-マクロ テンプレート タグが翻訳を通しても1文字も変わらないかを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ1行を失ってalpha ビルドを壊す事故（2026-09-07）から出た形を1カ所に集めました。タグは制御文法なので翻訳対象ではなく、1つでも欠落すると対が外れて `_Macro Syntax Error_` でビルド全体が失敗します。（本文修正テスト：この文は翻訳再実行時に反映されるべきです。）

<a id="wrapped-paragraph"></a>
### 段落を囲む条件付き { #wrapped-paragraph }

{% if "gov" not in build_flags %}
パブリック環境ではコンソールから直接設定できます。この段落は開くタグがすぐ上に付いているため、増分翻訳でタグと1つのユニットになります。事故が起きた形がまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件付き { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` であり、この文は開くタグと閉じるタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### サンプルブロックを囲む条件付き { #wrapped-example }

{% if "gov" not in build_flags %}
以下のサンプルは条件付きブロック内に `<details>` とコードフェンスが一緒に含まれています。タグ保護とフェンス保護が同じユニットで重なるケースです。

<details>
<summary>トークン発行要求サンプル</summary>

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
### 両方向の分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府網環境では担当者に発行手続きを問い合わせる必要があります。
{% else %}
パブリック環境ではコンソールから直接発行できます。
{% endif %}
