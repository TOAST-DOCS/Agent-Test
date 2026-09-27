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
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$インターフェイス ID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$インターフェイス パス |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$インターフェイス ステータス |{% endmacro %}
{# 上記のマクロは応答テーブルの共通行を生成します。コメントはレンダリングされません #}

<a id="sample-template-tags"></a>
## Sample > テンプレートタグ表記集 { #sample-template-tags }

このドキュメントは、mkdocs-macros テンプレートタグが翻訳を経た後でもビルドされ、タグ内に著者が入れた **韓国語文字列** が翻訳されるかを検証するためのフィクスチャです。`$[ product_name ]$` ドキュメントのタグは、実際のユーザーガイド(Private-DNS、Storage-Object-Storage、Storage-Online-NAS、nhn-cloud-foundry)からそのまま採用した表記です。

<a id="tt-set-literal"></a>
### 変数に格納された韓国語文字列 { #tt-set-literal }

ドキュメント上部の `set` ブロックは、ビルド環境ごとに異なる値を変数に格納します。このガイドが対象とするリージョンは $[ region_names ]$ であり、API ホストは `$[ api_host ]$` です。

| 分類 | 値 | 備考 |
|---|---|---|
| リージョン | $[ region_names ]$ | 環境によって異なります |
| API ホスト | `$[ api_host ]$` | アンダースコアが含まれた変数名です |
| クエリ開始時刻 | {{executionTime}} | ワークフローエンジンが置換するプレースホルダです |

<a id="tt-inline-literal"></a>
### 文内の条件付き文字列 { #tt-inline-literal }

コンテナの $[ "基本情報と暗号化情報" if encrypt else "基本情報" ]$ を確認し、アクセスポリシーと静的ウェブサイト設定を変更できます。変更内容は即座に反映されます。

!!! note "注記"
    通常のコンテナをオブジェクトロック コンテナに変更することはできません。

    オブジェクトロック コンテナはアーカイブ コンテナ$[ " または複製対象コンテナとして" if replication else "として" ]$ 指定することはできません。この制限は解除できません。

<a id="tt-macro-arg"></a>
### マクロ引数として渡された韓国語文字列 { #tt-macro-arg }

以下の表の行はマクロが生成します。2 番目の引数は説明の前に付加されるプレフィックスです。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('interface.', 'Newly created ') ]$
| interface.subnetId | Body | String | インターフェイスのサブネット ID |

プレフィックスなしで呼び出すと、説明がそのまま表示されます。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### タグのような UI プレースホルダ { #tt-ui-placeholder }

| 項目 | 必須 | 説明 |
|---|---|---|
| ユーザープロンプト テンプレート | X | 行ごとの入力値構成テンプレート。{{ カラム名 }} パターンが対応するカラム値に置換され、設定するとジョインデリミタより優先的に適用されます。カラム名は大文字と小文字を区別します。 |
| ジョイン デリミタ | X | 複数のカラムを 1 つの入力に結合する場合に挿入される文字列です。 |

<a id="tt-wrapped"></a>
### 段落を含む条件文 { #tt-wrapped }

{% if "gov" not in build_flags %}
公開環境ではコンソールから直接設定できます。この段落は開始タグがすぐ上に付いているため、段階的翻訳では開始タグと 1 つのユニットになります。設定は保存直後に適用されます。
{% endif %}

{% if "gov" in build_flags %}政府網環境では、担当者に発行手順を問い合わせる必要があります。{% else %}公開環境ではコンソールから直接発行できます。{% endif %}

<a id="tt-fenced"></a>
### コードブロック内のタグ { #tt-fenced }

mkdocs-macros はコードブロック内のタグも Jinja で処理するため、タグを **例として表示するには** `{% raw %}` で囲む必要があります。囲まない場合、条件文が評価され変数が置換されてサンプルが消えます。

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "Korea (Pangyo) Region" -%}
{% endif %}
$[ region_names ]$ / {{ column name }} / $[ api_host ]$
```
{% endraw %}

以下のブロックは韓国語を含まないコントロールグループです。翻訳を経た後もバイト単位で同一である必要があります。

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### 最後のセクション { #tt-tail }

このセクションは変更されていないコントロールグループです。段階的翻訳の後でも en/ja がバイト単位で同一である必要があります。