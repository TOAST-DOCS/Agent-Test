<!-- machine_translated: true -->

{%- set portal_url = "https://console.gov-nhncloudservice.com" if "gov" in build_flags
    else "https://console.nhncloudservice.com" -%}
<a id="sample-macro-shapes"></a>
## Sample > マクロタグの形態集 { #sample-macro-shapes }

このドキュメントは、mkdocs-macrosテンプレートタグが翻訳を経ても1文字も変わらないことを検証するためのフィクスチャです。Storage-Object-Storageの`ja/acl-guide.md`がタグ1行を失ってalphaビルドを破壊した事故(2026-09-07)から出た形態を1箇所に集めました。タグは制御文法なので翻訳対象ではなく、1つでも欠落するとペアがずれて`_Macro Syntax Error_`でビルド全体が失敗します。(本文修正テスト:この文は翻訳再実行時に反映される必要があります。)

<a id="wrapped-paragraph"></a>
### 段落を囲む条件分岐 { #wrapped-paragraph }

{% if "gov" not in build_flags %}
パブリック環境ではコンソールから直接設定できます。このパラグラフは、開くタグがすぐ上に付いているため、増分翻訳ではタグと1つのユニットになります。事故が発生した形態がまさにこれです。
{% endif %}
<br>

<a id="inline-condition"></a>
### 1行内の条件分岐 { #inline-condition }

{% if "gov" not in build_flags %}ポータルアドレスは`$[ portal_url ]$`であり、この文はタグを開くタグと閉じるタグが同じ行にあります。{% endif %}

<a id="wrapped-example"></a>
### 例ブロックを囲む条件分岐 { #wrapped-example }

{% if "gov" not in build_flags %}
以下の例は、条件分岐ブロック内に`<details>`とコードペンスが一緒に含まれています。タグ保護とペンス保護が同じユニットで重なるケースです。

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
| コンソール | `$[ portal_url ]$` | 環境によって異なります<br>表の行内でも置換されます |
| API | `$[ portal_url ]$/v2` | バージョンパスが付きます |

<a id="branch-both-ways"></a>
### 両分岐 { #branch-both-ways }

{% if "gov" in build_flags %}
政府網環境では、担当者に発行手続きについて確認する必要があります。
{% else %}
パブリック環境ではコンソールから直接発行できます。
{% endif %}