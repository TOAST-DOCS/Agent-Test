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
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$インターフェースパス |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$インターフェースの状態 |{% endmacro %}
{# 上のマクロはレスポンステーブルの共通行を生成します — コメントはレンダリングされません #}

<a id="sample-template-tags"></a>
## Sample > テンプレートタグの形式一覧 { #sample-template-tags }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳後もビルドされ、タグ内に著者が記述した**韓国語文字列**が翻訳されるかを検証するためのフィクスチャです。`$[ product_name ]$` ドキュメントのタグは、実際のユーザーガイド (Private-DNS、Storage-Object-Storage、Storage-Online-NAS、nhn-cloud-foundry) からそのまま取得した形式です。

<a id="tt-set-literal"></a>
### 変数に格納された韓国語文字列 { #tt-set-literal }

ドキュメント上部の `set` ブロックは、ビルド環境ごとに異なる値を変数に格納します。このガイドが対象とするリージョンは $[ region_names ]$ であり、API ホストは `$[ api_host ]$` です。

| 区分 | 値 | 備考 |
|---|---|---|
| リージョン | $[ region_names ]$ | 環境ごとに異なります。 |
| API ホスト | `$[ api_host ]$` | アンダースコアが含まれる変数名です。 |
| 照会開始時刻 | {{executionTime}} | ワークフローエンジンが置換するプレースホルダーです。 |

<a id="tt-inline-literal"></a>
### 文中の条件付き文字列 { #tt-inline-literal }

コンテナの $[ "基本情報と暗号化情報" if encrypt else "基本情報" ]$ を確認し、アクセスポリシーと静的ウェブサイト設定を変更できます。変更内容は即時反映されます。

!!! note "注記"
    通常のコンテナをオブジェクトロックコンテナに変更することはできません。

    オブジェクトロックコンテナはアーカイブコンテナ$[ " またはレプリケーション対象コンテナとして" if replication else "として" ]$指定することはできません。この制限は解除できません。

<a id="tt-macro-arg"></a>
### マクロ引数として渡された韓国語文字列 { #tt-macro-arg }

以下のテーブルの行はマクロが生成します。第2引数は説明の前に付く接頭辞です。

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
| ユーザープロンプトテンプレート | X | 行ごとの入力値構成テンプレート。{{ カラム名 }} パターンが該当カラムの値に置換され、設定すると結合区切り文字より優先されます。カラム名は大文字と小文字を区別します。 |
| 結合区切り文字 | X | 複数のカラムを1つの入力に結合する際に間に挿入する文字列です。 |

<a id="tt-wrapped"></a>
### 段落を囲む条件式 { #tt-wrapped }

{% if "gov" not in build_flags %}
共用環境ではコンソールからすぐに設定できます。この段落は開きタグが直上に付いているため、増分翻訳でタグと1ユニットになります。設定は保存後すぐに適用されます。
{% endif %}

{% if "gov" in build_flags %}政府ネットワーク環境では担当者に発行手続きをお問い合わせください。{% else %}共用環境ではコンソールから直接発行できます。{% endif %}

<a id="tt-fenced"></a>
### コードブロック内のタグ { #tt-fenced }

mkdocs-macros はコードブロック内のタグも Jinja で処理するため、タグを**例として表示するには** `{% raw %}` で囲む必要があります。囲まない場合、条件文が評価され変数が置換されて例が消えてしまいます。

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "韓国（パンギョ）リージョン" -%}
{% endif %}
$[ region_names ]$ / {{ カラム名 }} / $[ api_host ]$
```
{% endraw %}

以下のブロックは韓国語がない対照群です。翻訳後もバイト単位で同一である必要があります。

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### 最後のセクション { #tt-tail }

このセクションは変更されない対照群です。増分翻訳後も en/ja はバイト単位で同一である必要があります。