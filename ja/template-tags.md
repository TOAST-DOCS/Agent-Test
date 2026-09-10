<!-- machine_translated: true -->

<!-- pre-align:aligned sig=0877fab4a34e -->

{% if "gov" in build_flags -%}
  {%- set api_host      = "api-tt.gov-nhncloudservice.com" -%}
  {%- set region_names  = "韓国（パンギョ）リージョン" -%}
  {%- set encrypt       = false -%}
{%- elif "ngsc" in build_flags -%}
  {%- set api_host      = "api-tt.ngsc.go.kr" -%}
  {%- set region_names  = "韓国（テグ）リージョン" -%}
  {%- set encrypt       = false -%}
{%- else -%}
  {%- set api_host      = "api-tt.nhncloudservice.com" -%}
  {%- set region_names  = "韓国（パンギョ）リージョン<br>韓国（ピョンチョン）リージョン<br>韓国（クァンジュ）リージョン<br>韓国（プサン）リージョン" -%}
  {%- set encrypt       = true -%}
{%- endif -%}
{%- set replication = "gov" not in build_flags -%}
{%- set product_name = "テンプレートタグサンプル" -%}

{% macro tt_response_table(prefix='', desc_prefix='') -%}
| $[ prefix ]$id | Body | String | $[ desc_prefix ]$インターフェイスID |
| $[ prefix ]$path | Body | String | $[ desc_prefix ]$インターフェイスパス |
| $[ prefix ]$status | Body | String | $[ desc_prefix ]$インターフェイスの状態 |{% endmacro %}
{# 上のマクロはレスポンス表の共通行を作る — コメントはレンダリングされない #}

<a id="sample-template-tags"></a>
## Sample > テンプレートタグの形一覧 { #sample-template-tags }

このドキュメントは、mkdocs-macrosテンプレートタグが翻訳後もビルドでき、タグの中に著者が入れた**韓国語の文字列**が翻訳されるかを検証するためのフィクスチャです。`$[ product_name ]$`ドキュメントのタグは、実際のユーザーガイド(Private-DNS、Storage-Object-Storage、Storage-Online-NAS、nhn-cloud-foundry)からそのまま持ってきた形です。

<a id="tt-set-literal"></a>
### 変数に入れた韓国語の文字列 { #tt-set-literal }

ドキュメント上部の`set`ブロックは、ビルド環境ごとに異なる値を変数に入れます。このガイドが扱うリージョンは$[ region_names ]$で、APIホストは`$[ api_host ]$`です。

| 区分 | 値 | 備考 |
|---|---|---|
| リージョン | $[ region_names ]$ | 環境ごとに異なります |
| APIホスト | `$[ api_host ]$` | アンダースコアが入った変数名です |
| 照会開始時間 | {{executionTime}} | ワークフローエンジンが置き換えるプレースホルダーです |

<a id="tt-inline-literal"></a>
### 文中の条件付き文字列 { #tt-inline-literal }

コンテナの $[ "基本情報と暗号化情報" if encrypt else "基本情報" ]$ を確認し、アクセスポリシーと静的Webサイトの設定を変更できます。変更内容は即時反映されます。

!!! note "参考"
    通常のコンテナをオブジェクトロックコンテナに変更することはできません。

    オブジェクトロックコンテナはアーカイブコンテナ$[ " またはレプリケーション対象コンテナ" if replication else "" ]$として指定することはできません。この制限は解除することはできません。

<a id="tt-macro-arg"></a>
### マクロ引数として渡した韓国語の文字列 { #tt-macro-arg }

下の表の行はマクロが作ります。2番目の引数は説明の前に付く接頭辞です。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('interface.', '新しく作成された ') ]$
| interface.subnetId | Body | String | インターフェイスのサブネット ID |

接頭辞なしで呼び出すと、説明がそのまま表示されます。

| 名前 | 種類 | 形式 | 説明 |
|---|---|---|---|
$[ tt_response_table('volume.') ]$

<a id="tt-ui-placeholder"></a>
### タグのように見えるUIプレースホルダー { #tt-ui-placeholder }

| 項目 | 必須 | 説明 |
|---|---|---|
| ユーザープロンプトテンプレート | X | 行ごとの入力値構成テンプレート。{{ カラム名 }} パターンが該当カラムの値に置換され、設定すると結合区切り文字より優先して適用されます。カラム名は大文字と小文字を区別します。 |
| 結合区切り文字 | X | 複数のカラムを1つの入力にまとめるとき、その間に入れる文字列です。 |

<a id="tt-wrapped"></a>
### 段落を囲む条件文 { #tt-wrapped }

{% if "gov" not in build_flags %}
共有環境では、コンソールから直接設定できます。この段落は開始タグが直上に隣接しており、増分翻訳においてタグと一つのユニットになります。設定は保存後すぐに反映されます。
{% endif %}

{% if "gov" in build_flags %}政府ネットワーク環境では、担当者に発行手順を問い合わせる必要があります。{% else %}パブリック環境では、コンソールから直接発行できます。{% endif %}

<a id="tt-fenced"></a>
### コードブロック内のタグ { #tt-fenced }

mkdocs-macrosはコードブロック内のタグもJinjaとして処理するため、タグを**例として見せる**には`{% raw %}`で囲む必要があります。囲まないと条件文が評価され、変数が置き換えられて例が消えてしまいます。

{% raw %}
```jinja
{% if "gov" in build_flags %}
  {%- set region_names = "韓国(板橋)リージョン" -%}
{% endif %}
$[ region_names ]$ / {{ カラム名 }} / $[ api_host ]$
```
{% endraw %}

下のブロックは韓国語が入っていない対照群です。翻訳を経てもバイト単位で同じでなければなりません。

```
$ curl -X POST -H 'Content-Type: application/json' \
  https://$[ api_host ]$/v2/containers
```

<a id="tt-tail"></a>
### 最後の節 { #tt-tail }

この節は変更されない対照群です。増分翻訳の後もen/jaはバイト単位で同じでなければなりません。
