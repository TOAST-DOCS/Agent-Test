<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロタグ形状コレクション { #sample-macro-shapes }

このドキュメントは、mkdocs-macrosテンプレートタグが翻訳を通じても1文字も変わらないかを検証するためのフィクスチャです。Storage-Object-Storageの`ja/acl-guide.md`がタグ1行を失いalphaビルドを破壊したインシデント(2026-09-07)から生まれた形状をここに集めました。タグは制御構文であるため翻訳対象ではなく、1つでも失われるとペアがずれ`_Macro Syntax Error_`でビルド全体が失敗します。(本文修正テスト:この文は翻訳再実行時に反映される必要があります。)

<a id="wrapped-paragraph"></a>
### 段落を包む条件分岐 { #wrapped-paragraph }

{% if "gov" not in build_flags %}
公開環境ではコンソールから直接設定できます。この段落は開きタグがすぐ上に付いているため、増分翻訳でタグと1つのユニットになります。インシデントが発生した形がまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件分岐 { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは`$[ portal_url ]$`であり、この文は開きタグと閉じタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例示ブロックを包む条件分岐 { #wrapped-example }

{% if "gov" not in build_flags %}
下記の例は条件分岐ブロック内に`<details>`とコードフェンスが一緒に含まれています。タグ保護とフェンス保護が同じユニットで重なるケースです。

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
| API | `$[ portal_url ]$/v2` | バージョンパスが付加されます |

<a id="branch-both-ways"></a>
### 両方の分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府ネットワーク環境では、担当者に発行手順を問い合わせる必要があります。
{% else %}
公開環境ではコンソールから直接発行できます。
{% endif %}
