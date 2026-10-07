<!-- pre-align:aligned sig=18e686d70cbe -->

<a id="delete-mirror-overview"></a>
## 削除ミラーテスト { #delete-mirror-overview }

この文書は、ko PRがセクション内のサブブロック1つを**削除のみ**し、同じPRがen/jaでもそのブロックを
すでに削除しているケース(TOAST-DOCS/Network#160 → #163、2026-10-07)を再現するフィクスチャです。
koが変更していない兄弟の箇条書きがen/jaで変わった場合は欠陥です。

<a id="delete-mirror-2025-11-25"></a>
### 2025. 11. 25. { #delete-mirror-2025-11-25 }

<a id="delete-mirror-2025-11-25-added-features"></a>
#### 機能追加

##### VPN Gateway
* VPNが接続されたVPCにTransit Hubを接続すると、Transit Hubで接続された他のプロジェクトのVPCでもオンプレミスネットワークとのVPN通信をサポートします。(接続された帯域でVPN Connectionの追加作成が必要)

##### Service Gateway
* Service Gateway作成時にユーザーがNAT IPを固定して作成できるように改善されました。

##### Load Balancer
* リスナーごとのユーザー定義レスポンス設定機能が追加されました。
* X-Forwarded-*ヘッダーの有効化/無効化機能が追加されました。

<a id="delete-mirror-2024-05-28"></a>
### 2024. 05. 28. { #delete-mirror-2024-05-28 }

<a id="delete-mirror-2024-05-28-feature-updates"></a>
#### 機能改善

##### Load Balancer
* ロードバランサー作成時に基本情報でIPアクセス制御設定を一緒に行えるように改善されました。

<a id="delete-mirror-control"></a>
### 2023. 03. 14. { #delete-mirror-control }

<a id="delete-mirror-control-added-features"></a>
#### 機能追加

##### Service Gateway
* Service Gatewayサービスが発売されました。
