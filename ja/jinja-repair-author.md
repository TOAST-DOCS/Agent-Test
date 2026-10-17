<a id="jinja-repair-sample"></a>
## Jinja復元サンプル { #jinja-repair-sample }

この文書はJinja構文エラー復元e2eのフィクスチャーです。ここでは正常な状態で保管し、e2eがセッションブランチに欠陥を仕込みます。

<a id="jinja-repair-closer"></a>
### 公共機関専用の表 { #jinja-repair-closer }

すべての環境に共通の説明です。

{% if "gov" in build_flags %}
公共機関用環境でのみ提供するエンドポイントです。

| リージョン | エンドポイント |
|---|---|
| 韓国(板橋)リージョン | https://kr1-api.gov-nhncloudservice.com |
{% endif %}

<a id="jinja-repair-opener"></a>
### 環境別の案内 { #jinja-repair-opener }

次の案内は環境ごとに異なります。

{% if "gov" not in build_flags %}
!!! tip "ポイント"
    一般環境ではコンソールから直接申請できます。
{% else %}
!!! tip "ポイント"
    公共機関用環境では担当者の承認後に使用できます。
{% endif %}

申請後10分以内に適用されます。

<a id="jinja-repair-author"></a>
### リリース予定の機能 { #jinja-repair-author }

現在提供している機能は次のとおりです。

- インスタンスの作成
- インスタンスの削除

{% if release_2026_11 %}
!!! note "参考"
    2026年11月リリース予定の機能はスナップショットの予約です。

リリース日程は状況により変更される場合があります。
{% endif %}

<a id="jinja-repair-typo"></a>
### リージョンリスト { #jinja-repair-typo }

{% if "ncgn" in build_flags %}
- 韓国(大邱)リージョン
{% endif %}
- 韓国(板橋)リージョン
- 韓国(平村)リージョン
