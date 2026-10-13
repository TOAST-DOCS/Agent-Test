<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロ タグ パターン集 { #sample-macro-shapes }

本ドキュメントは、mkdocs-macros テンプレート タグが翻訳を経ても1文字も変わらないかを検証するためのフィクスチャです。Storage-Object-Storage の `ja/acl-guide.md` がタグ1行を失い、alpha ビルドを破壊した事故(2026-09-07)で見つかったパターンをまとめています。タグは制御文法であり翻訳対象ではなく、1つでも欠落するとペアが崩れて `_Macro Syntax Error_` でビルド全体が失敗します。(本文修正テスト: この文は翻訳再実行時に反映される必要があります。)

<a id="wrapped-paragraph"></a>
### 段落を囲む条件付き { #wrapped-paragraph }

{% if "gov" not in build_flags %}
公開環境ではコンソールから直接設定できます。本段落は開きタグがすぐ上に付いているため、差分翻訳ではタグと1つのユニットになります。この事故は正確にこのパターンです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件付き { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは `$[ portal_url ]$` で、この文は開きタグと閉じタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを囲む条件付き { #wrapped-example }

{% if "gov" not in build_flags %}
次の例は条件付きブロック内に `<details>` とコード フェンスが共に含まれています。タグ保護とフェンス保護が同じユニット内で重複する場合です。

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
| コンソール | `$[ portal_url ]$` | 環境により異なります<br>表行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョン パスが付きます |

<a id="branch-both-ways"></a>
### 両側分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府網環境では担当者に発行手順についてお問い合わせください。
{% else %}
公開環境ではコンソールから直接発行できます。
{% endif %}