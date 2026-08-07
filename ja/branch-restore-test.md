<!-- machine_translated: true -->

<!-- pre-align:aligned sig=9b1876e3ba07 -->

# ブランチ復元テスト

## 目的

`translate_pr.py` がマージ済み PR の削除された head ブランチを復元した後、翻訳を実行するかどうかを検証するフィクスチャです。

## シナリオ

1. この PR を merged + delete-branch で処理します。
2. `translate_pr.py` をこの PR URL で実行します。
3. ログに `Restoring deleted source branch` が含まれている必要があり、翻訳 PR が開かれる必要があります。