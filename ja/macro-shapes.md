<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロタグの形状集 { #sample-macro-shapes }

本ドキュメントは、mkdocs-macrosテンプレートタグが翻訳を経ても一文字も変わらないことを検証するためのフィクスチャです。Storage-Object-Storageの`ja/acl-guide.md`がタグ1行を失ってalphaビルドを壊した事故(2026-09-07)から出た形状をまとめました。タグは制御文法なので翻訳対象ではなく、1つでも欠落すると対が食い違い、`_Macro Syntax Error_`でビルド全体が失敗します。(本文修正テスト: この文は翻訳再実行時に反映される必要があります。)

<a id="wrapped-paragraph"></a>
### 段落を囲む条件分岐 { #wrapped-paragraph }

{% if "gov" not in build_flags %}
パブリック環境ではコンソールから直ちに設定できます。この段落は開くタグがすぐ上に付いているため、増分翻訳ではタグと1つのユニットになります。事故が起きた形状がまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件分岐 { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは`$[ portal_url ]$`であり、この文は開くタグと閉じるタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを囲む条件分岐 { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例は条件分岐ブロック内に`<details>`とコードフェンスが一緒に含まれています。タグ保護とフェンス保護が同じユニットで重なる場合です。

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
| コンソール | `$[ portal_url ]$` | 環境によって異なります<br>表の行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョンパスが付きます |

<a id="branch-both-ways"></a>
### 両方の分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府網環境では担当者に発行手順を問い合わせる必要があります。
{% else %}
パブリック環境ではコンソールから直接発行できます。
{% endif %}
