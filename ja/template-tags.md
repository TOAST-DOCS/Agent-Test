<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0877fab4a34e -->

{% if "gov" in build_flags -%}
  {%- set api_host      = "api-tt.gov-nhncloudservice.com" -%}
  {%- set region_names  = "Korea (Pangyo) Region" -%}
  {%- set encrypt       = false -%}
{%- elif "ngsc" in build_flags -%}
  {%- set api_host      = "api-tt.ngsc.go.kr" -%}
  {%- set region_names  = "Korea (Daegu) Region" -%}
  {%- set encrypt       = false -%}
{%- else -%}
  {%- set api_host      = "api-tt.nhncloudservice.com" -%}
  {%- set region_names  = "Korea (Pangyo) Region<br>Korea (Pyeongchon) Region<br>Korea (Gwangju) Region<br>Korea (Busan) Region" -%}
  {%- set encrypt       = true -%}
{%- endif -%}
{%- set replication = "gov" not in build_flags -%}
{%- set product_name = "Template Tag Sample" -%}

{% macro tt_response_table(prefix='', desc_prefix='') -%}
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$Interface ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$Interface Path |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$Interface Status |{% endmacro %}
{# 上のマクロは応答テーブルの共通行を生成します — コメントはレンダリングされません #}

<a id="sample-template-tags"></a>
## Sample > Template Tag Sample Collection { #sample-template-tags }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳後もビルドされ、タグ内に著者が配置した**韓国語の文字列**が翻訳されるかどうかを検証するためのフィクスチャです。`$[ product_name ]$` ドキュメントのタグは、実際のユーザーガイド (Private-DNS、Storage-Object-Storage、Storage-Online-NAS、nhn-cloud-foundry) からそのまま取得した形状です。

<a id="tt-set-literal"></a>
### Variables containing Korean character strings { #tt-set-literal }

ドキュメント上部の `set` ブロックは、ビルド環境ごとに異なる値を変数に格納します。このガイドが対象とするリージョンは $[ region_names ]$ であり、API ホストは `$[ api_host ]$` です。

| 区分 | 値 | 備考 |
|---|---|---|
| リージョン | $[ region_names ]$ | 環境によって異なります |
| API ホスト | `$[ api_host ]$` | アンダースコアが含まれる変数名です |
| 照会開始時刻 | {{executionTime}} | ワークフローエンジンによって置換されるプレースホルダです |

<a id="tt-inline-literal"></a>
### Conditional strings in sentences { #tt-inline-literal }

コンテナの $[ "basic and encryption information" if encrypt else "basic information" ]$ を確認し、アクセスポリシーと静的ウェブサイト設定を変更できます。変更内容は即座に反映されます。

!!! note "注記"
    通常のコンテナをオブジェクトロック コンテナに変更することはできません。

    オブジェクトロック コンテナはアーカイブコンテナ$[ " or replication target container" if replication else "" ]$ として指定することはできません。この制限は解除できません。

<a id="tt-macro-arg"></a>
### Korean character strings passed as macro arguments { #tt-macro-arg }

以下の表の行はマクロによって生成されます。2 番目の引数は説明の前に付加されるプリフィックスです。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('interface.', 'Newly created ') ]$
| interface.subnetId | Body | String | インターフェイスのサブネット ID |

プリフィックスなしで呼び出すと、説明がそのまま表示されます。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### UI placeholders that look like tags { #tt-ui-placeholder }

| 項目 | 必須 | 説明 |
|---|---|---|
| ユーザープロンプト テンプレート | X | 行ごとの入力値構成テンプレート。{{ column name }} パターンは該当列の値に置換され、設定すると結合区切り文字よりも優先して適用されます。列名は大文字と小文字を区別します。 |
| 結合区切り文字 | X | 複数の列を 1 つの入力に結合する場合に、その間に挿入される文字列です。 |

<a id="tt-wrapped"></a>
### Conditional wrapping paragraphs { #tt-wrapped }

{% if "gov" not in build_flags %}
パブリック環境ではコンソールから直接設定できます。この段落は開始タグがすぐ上に配置されているため、増分翻訳ではタグと 1 つのユニットになります。設定は保存直後に適用されます。
{% endif %}

{% if "gov" in build_flags %}政府ネットワーク環境では、担当者に発行手順について確認してください。{% else %}パブリック環境ではコンソールから直接発行できます。{% endif %}

<a id="tt-fenced"></a>
### Tags in code blocks { #tt-fenced }

mkdocs-macros はコードブロック内のタグも Jinja でも処理するため、タグを**サンプルとして表示**するには `{% raw %}` で囲む必要があります。囲まない場合、条件文が評価され、変数が置換されてサンプルが消えます。

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "Korea (Pangyo) Region" -%}
{% endif %}
$[ region_names ]$ / {{ column name }} / $[ api_host ]$
```
{% endraw %}

以下のブロックは韓国語のない対照群です。翻訳後もバイト単位で同じである必要があります。

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### Final section { #tt-tail }

このセクションは変更されない対照群です。増分翻訳後も en/ja がバイト単位で同じである必要があります。