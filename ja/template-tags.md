<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0877fab4a34e -->

{% if "gov" in build_flags -%}
  {%- set api_host      = "api-tt.gov-nhncloudservice.com" -%}
  {%- set region_names  = "韓国(パンギョ) リージョン" -%}
  {%- set encrypt       = false -%}
{%- elif "ngsc" in build_flags -%}
  {%- set api_host      = "api-tt.ngsc.go.kr" -%}
  {%- set region_names  = "韓国(テグ) リージョン" -%}
  {%- set encrypt       = false -%}
{%- else -%}
  {%- set api_host      = "api-tt.nhncloudservice.com" -%}
  {%- set region_names  = "韓国(パンギョ) リージョン<br>韓国(ピョンチョン) リージョン<br>韓国(クァンジュ) リージョン<br>韓国(プサン) リージョン" -%}
  {%- set encrypt       = true -%}
{%- endif -%}
{%- set replication = "gov" not in build_flags -%}
{%- set product_name = "テンプレートタグサンプル" -%}

{% macro tt_response_table(prefix='', desc_prefix='') -%}
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$インターフェース ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$インターフェースのパス |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$インターフェースのステータス |{% endmacro %}
{# 上記のマクロはレスポンステーブルの共通行を生成します — コメントはレンダリングされません #}

<a id="sample-template-tags"></a>
## Sample > テンプレートタグの形式一覧 { #sample-template-tags }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳後もビルドされること、およびタグ内に著者が記述した**韓国語文字列**が翻訳されることを検証するためのフィクスチャです。`$[ product_name ]$` ドキュメントのタグは、実際のユーザーガイド(Private-DNS、Storage-Object-Storage、Storage-Online-NAS、nhn-cloud-foundry)からそのまま採用した形式です。

<a id="tt-set-literal"></a>
### 変数に格納された韓国語文字列 { #tt-set-literal }

ドキュメント上部の `set` ブロックは、ビルド環境ごとに異なる値を変数に格納します。このガイドが対象とするリージョンは $[ region_names ]$ であり、API ホストは `$[ api_host ]$` です。

| 項目 | 値 | 備考 |
|---|---|---|
| リージョン | $[ region_names ]$ | 環境によって異なります。|
| API ホスト | `$[ api_host ]$` | アンダースコアを含む変数名です。|
| 照会開始時刻 | {{executionTime}} | ワークフローエンジンが置き換えるプレースホルダーです。|

<a id="tt-inline-literal"></a>
### 文中の条件付き文字列 { #tt-inline-literal }

コンテナの $[ "基本情報と暗号化情報" if encrypt else "基本情報" ]$ を確認し、アクセスポリシーと静的ウェブサイトの設定を変更できます。変更内容は即座に反映されます。

!!! note "注記"
    通常のコンテナをオブジェクトロックコンテナに変更することはできません。

    オブジェクトロックコンテナは、アーカイブコンテナ$[ " または複製対象コンテナとして" if replication else "として" ]$指定することはできません。この制限は解除できません。

<a id="tt-macro-arg"></a>
### マクロの引数として渡した韓国語文字列 { #tt-macro-arg }

以下のテーブルの行はマクロが生成します。2番目の引数は、説明の前に付く接頭辞です。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('interface.', '新しく作成された ') ]$
| interface.subnetId | Body | String | インターフェースのサブネット ID |

接頭辞なしで呼び出すと、説明がそのまま表示されます。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### タグのように見える UI プレースホルダー { #tt-ui-placeholder }

| 項目 | 必須 | 説明 |
|---|---|---|
| ユーザープロンプトテンプレート | X | 行ごとの入力値構成テンプレート。{{ カラム名 }} パターンが該当する列の値に置換されます。設定した場合、結合区切り文字より優先して適用されます。列名は大文字と小文字を区別します。|
| 結合区切り文字 | X | 複数の列を1つの入力にまとめる際に間に挿入する文字列です。|

<a id="tt-wrapped"></a>
### 段落を囲む条件式 { #tt-wrapped }

{% if "gov" not in build_flags %}
共用環境では、コンソールから直接設定できます。この段落は開始タグがすぐ上に配置されているため、増分翻訳ではタグと1つのユニットになります。設定は保存後すぐに反映されます。
{% endif %}

{% if "gov" in build_flags %}政府網環境では、担当者に発行手続きをお問い合わせください。{% else %}共用環境では、コンソールから直接発行できます。{% endif %}

<a id="tt-fenced"></a>
### コードブロック内のタグ { #tt-fenced }

mkdocs-macros はコードブロック内のタグも Jinja で処理するため、タグを**例として表示するには** `{% raw %}` で囲む必要があります。囲まない場合、条件文が評価され変数が置換されて、例示が消えてしまいます。

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "韓国（パンギョ）リージョン" -%}
{% endif %}
$[ region_names ]$ / {{ カラム名 }} / $[ api_host ]$
```
{% endraw %}

以下のブロックは韓国語を含まない対照群です。翻訳後もバイト単位で同一でなければなりません。

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### 最後のセクション { #tt-tail }

このセクションは変更されない対照群です。増分翻訳後も en/ja がバイト単位で同一でなければなりません。