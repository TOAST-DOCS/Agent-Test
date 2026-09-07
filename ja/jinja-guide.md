<!-- machine_translated: true -->

<!-- pre-align:aligned sig=cdbc88f0a12c -->

{%- set api_host = "api-jinja.gov-nhncloudservice.com" if "gov" in build_flags else "api-jinja.nhncloudservice.com" -%}
<a id="sample-jinja-guide"></a>
## Sample > Jinja ガイド { #sample-jinja-guide }

{%- if "gov" not in build_flags %}
このドキュメントは mkdocs-macros の Jinja 条件分岐と変数置換が ko/en/ja の 3 つの言語で同じように維持されるかどうかを検証するためのフィクスチャです。タグは制御構文であるため翻訳されず、本文のみが言語別に異なります。
{%- endif %}

<a id="endpoint"></a>
### エンドポイント { #endpoint }

{% if "gov" in build_flags -%}
政府ネットワーク環境では、専用エンドポイントを使用します。パブリックドメインではアクセスできません。（タグブロック内のテキスト変更：この文は、翻訳を再実行するときに反映される必要があります。）
{% else -%}
パブリック環境では、デフォルトエンドポイントを使用します。リージョン別ホストについては、下表を参照してください。
{% endif %}

API ホストは `$[ api_host ]$` です。

| リージョン | ホスト | 備考 |
|---|---|---|
| 韓国(パンギョ) | kr1-$[ api_host ]$ | 基本リージョン<br>常時運営 |
| 韓国(ピョンチョン) | kr2-$[ api_host ]$ | 二重化構成 |

<a id="auth"></a>
### 認証 { #auth }

{% if "ngsc" in build_flags -%}
NGSC 環境は別途の認証手順に従います。担当者に発行手順をお問い合わせください。
{% else -%}
トークンを発行し、リクエストヘッダに含めて呼び出します。トークンには有効期限があります。
{% endif %}

<a id="reference"></a>
### References { #reference }

- [API 使用準備](/nhncloud/ja/public-api/)
