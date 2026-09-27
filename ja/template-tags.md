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
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$インターフェース ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$インターフェース パス |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$インターフェース ステータス |{% endmacro %}
{# 上記のマクロはレスポンステーブルの共通行を作成します — コメントはレンダリングされません #}

<a id="sample-template-tags"></a>
## Sample > テンプレートタグの例の集まり { #sample-template-tags }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳を経た後もビルドされ、タグ内に著者が挿入した**日本語文字列**が翻訳されるかどうかを検証するためのフィクスチャです。`$[ product_name ]$` ドキュメント内のタグは、実際のユーザーガイド（Private-DNS、Storage-Object-Storage、Storage-Online-NAS、nhn-cloud-foundry）からそのまま採取されています。

<a id="tt-set-literal"></a>
### 日本語文字列を含む変数 { #tt-set-literal }

ドキュメント上部の `set` ブロックは、ビルド環境に応じて異なる値を変数に割り当てます。本ガイドで取り扱うリージョンは $[ region_names ]$ であり、API ホストは `$[ api_host ]$` です。

| 項目 | 値 | 備考 |
|---|---|---|
| リージョン | $[ region_names ]$ | 環境ごとに異なります |
| API ホスト | `$[ api_host ]$` | アンダースコア付きの変数名です |
| クエリ開始時刻 | {{executionTime}} | ワークフローエンジンによって置換されるプレースホルダーです |

<a id="tt-inline-literal"></a>
### 文内の条件付き文字列 { #tt-inline-literal }

コンテナの $[ "基本情報と暗号化情報" if encrypt else "基本情報" ]$ を確認し、アクセスポリシーと静的ウェブサイト設定を変更できます。変更内容は即座に反映されます。

!!! note "注記"
    通常のコンテナをオブジェクトロックコンテナに変更することはできません。

    オブジェクトロックコンテナはアーカイブコンテナ$[ " または複製対象コンテナとして" if replication else "として" ]$ 指定することはできません。この制限を解除することはできません。

<a id="tt-macro-arg"></a>
### マクロ引数として渡される日本語文字列 { #tt-macro-arg }

下表の行はマクロが生成します。第 2 引数は説明の前に付加されるプレフィックスです。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('interface.', '新規作成された ') ]$
| interface.subnetId | Body | String | インターフェースのサブネット ID |

プレフィックスなしで呼び出すと、説明がそのまま表示されます。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### タグのように見える UI プレースホルダー { #tt-ui-placeholder }

| 項目 | 必須 | 説明 |
|---|---|---|
| ユーザープロンプトテンプレート | X | 行別入力値構成テンプレート。{{ 列名 }} パターンが対応する列値に置換され、設定した場合は結合区切り文字より優先されます。列名は大文字と小文字を区別します。 |
| 結合区切り文字 | X | 複数の列を 1 つの入力に結合する際に間に挿入する文字列です。 |

<a id="tt-wrapped"></a>
### 段落を囲む条件付き { #tt-wrapped }

{% if "gov" not in build_flags %}
公用環境ではコンソールから直接設定できます。本段落は開きタグがすぐ上に付加されているため、増分翻訳ではタグと 1 つのユニットになります。設定は保存直後に適用されます。
{% endif %}

{% if "gov" in build_flags %}政府網環境では担当者に発行手順を問い合わせる必要があります。{% else %}公用環境ではコンソールから直接発行できます。{% endif %}

<a id="tt-fenced"></a>
### コードブロック内のタグ { #tt-fenced }

mkdocs-macros はコードブロック内のタグも Jinja として処理するため、タグを**例として表示するには** `{% raw %}` で囲む必要があります。囲まない場合、条件文が評価され変数が置換されて例が消えます。

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "韓国(パンギョ) リージョン" -%}
{% endif %}
$[ region_names ]$ / {{ カラム名 }} / $[ api_host ]$
```
{% endraw %}

下記ブロックは日本語を含まない対照群です。翻訳を経た後も、バイト単位で同じである必要があります。

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### 最後のセクション { #tt-tail }

本セクションは変更されない対照群です。増分翻訳後も en/ja がバイト単位で同じである必要があります。