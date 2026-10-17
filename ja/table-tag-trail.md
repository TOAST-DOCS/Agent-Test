<!-- machine_translated: true -->

<!-- pre-align:aligned sig=6cb69b3e1d0e -->

<a id="ttt"></a>
# table-tag-trail e2e フィクスチャ

この文書は自動生成された e2e フィクスチャです (20261017-014633)。

<a id="ttt-reuse"></a>
## ソートパラメータ { #ttt-reuse }

| 名前 | 説明 |
| --- | --- |
| sort_dir | ソート方向 |
{%- if "public" in build_flags %}
| member_status | メンバーの状態 |
{% else %}
{% endif %}

リストをソートするときに使用します。

<a id="ttt-retx"></a>
## ページングパラメータ { #ttt-retx }

| 名前 | 説明 |
| --- | --- |
| limit | 一度に照会する件数 |
| offset | 照会開始位置(0から) |
{% if "gov" in build_flags %}
{% endif %}

リストを分けて照会するときに使用します。

<a id="ttt-append"></a>
## フィルタパラメータ { #ttt-append }

{%- if "public" in build_flags %}
| 名前 | 説明 |
| --- | --- |
| name | 名前フィルタ |
| status | 状態フィルタ |
| createdFrom | 作成日時開始 |
| createdTo | 作成日時終了 |
{% endif %}

リストを絞り込むときに使用します。

<a id="ttt-blank"></a>
## 検索パラメータ { #ttt-blank }

| 名前 | 説明 |
| --- | --- |
| keyword | 検索キーワード |
| scope | 検索範囲 |

{% if "gov" in build_flags %}
公共環境では検索範囲が制限されます。
{% endif %}

リストを検索するときに使用します。

<a id="ttt-plain"></a>
## レスポンスフィールド { #ttt-plain }

| 名前 | 説明 |
| --- | --- |
| totalCount | 条件に合う全体件数 |
| items | 項目リスト |

レスポンス本文のフィールドです。
