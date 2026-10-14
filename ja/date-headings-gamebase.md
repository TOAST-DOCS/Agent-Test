<!-- machine_translated: true -->

<!-- pre-align:aligned sig=602ad029c65d -->

<a id="game-gamebase-release-notes-unity"></a>
## Game > Gamebase > リリースノート > Unity { #game-gamebase-release-notes-unity }

<a id="2-83-0-2026-10-13"></a>
### 2.83.0 (2026. 10. 13.) { #2-83-0-2026-10-13 }
[SDKダウンロード](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.83.0/GamebaseSDK-Unity.zip)

<a id="830-2026-10-13-added-features"></a>
#### 機能追加
* (Windows, macOS) WebビューでPredefined Custom Schemeをサポートしています。
* (Windows, macOS) 点検ポップアップに点検の詳細ページを表示する「詳細を表示」ボタンを追加しました。
* GamebaseResponse.Purchase.PurchasableReceiptにextrasフィールドを追加しました。

<a id="830-2026-10-13-feature-updates"></a>
#### 機能改善/変更
* Unityエディターの高速Play Mode進入(Fast Enter Play Mode)環境をサポートしています。
* GamebaseResponse.Event.PurchasableReceiptを非推奨化しました。GamebaseResponse.Purchase.PurchasableReceiptを使用してください。

<a id="830-2026-10-13-bug-fixes"></a>
#### バグ修正
* (Android, iOS) PURCHASE_UPDATEDイベントのレシート情報の一部が欠落する問題を修正しました。
* (Windows, macOS, WebGL) 特定の状況でログインを再度試行できない問題を修正しました。
* (WebGL) ChangeLoginでアカウント切り替え後にアプリを再起動すると、切り替え前のアカウントでログインされる問題を修正しました。
* (macOS) Apple Silicon環境でWebビューが正常に表示されない問題を修正しました。
* (Windows, macOS) Webビューを使用した後にアプリを終了するとクラッシュが発生する問題を修正しました。
* (Windows, macOS) WebビューでGamebase://openbrowser、gamebase://dismissスキームが重複して処理される問題を修正しました。

<a id="830-2026-10-13-platform-specific-changes"></a>
#### プラットフォーム別の変更事項
* [Gamebase Android SDK 2.83.0](./release-notes-android/#2-83-0-2026-09-17)
* [Gamebase iOS SDK 2.82.1](./release-notes-ios/#2-82-1-2026-08-25)

<a id="2-82-0-2026-08-11"></a>
### 2.82.0 (2026. 08. 11.) { #2-82-0-2026-08-11 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.82.0/GamebaseSDK-Unity.zip)

<a id="820-2026-08-11-feature-updates"></a>
#### 機能改善・変更
* (Android、iOS) 無効なデータに対する検証ロジックを改善しました。

<a id="820-2026-08-11-bug-fixes"></a>
#### 不具合の修正
* (Windows、macOS) Webビューでgamebase://openbrowserスキームが正常に処理されない問題を修正しました。

<a id="820-2026-08-11-platform-specific-changes"></a>
#### プラットフォーム別の変更事項
* [Gamebase Android SDK 2.82.0](./release-notes-android/#2-82-0-2026-07-28)
* [Gamebase iOS SDK 2.82.0](./release-notes-ios/#2-82-0-2026-07-28)

<a id="820-2026-08-11-setting-tool-v301"></a>
#### Setting Tool (v3.0.1)

* WebGLプラットフォーム専用アダプタのインストールが可能になります。

<a id="2-81-4-2026-07-14"></a>
### 2.81.4 (2026. 07. 14.) { #2-81-4-2026-07-14 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.81.4/GamebaseSDK-Unity.zip)

<a id="814-2026-07-14-bug-fixes"></a>
#### 不具合の修正
* (Windows, macOS) 不安定なネットワーク環境でWebsocketの再接続を試みる際、断続的にエラーが発生する問題を修正しました。

<a id="814-2026-07-14-feature-updates"></a>
#### 機能改善
* Gamebase SDKにAssembly Definition(.asmdef)を適用しました。

<a id="814-2026-07-14-platform-specific-changes"></a>
#### プラットフォーム別の変更事項
* [Gamebase Android SDK 2.81.0](./release-notes-android/#2-81-0-2026-06-23)
* [Gamebase iOS SDK 2.81.3](./release-notes-ios/#2-81-3-2026-05-27)

<a id="2-81-3-2026-05-27"></a>
### 2.81.3 (2026. 05. 27.) { #2-81-3-2026-05-27 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.81.3/GamebaseSDK-Unity.zip)

<a id="813-2026-05-27-bug-fixes"></a>
#### 不具合の修正
* (Windows, MacOS, WebGL) Log&Crashサーバーへのログ送信時、userFieldsに入力するキーと値のペアの値がnullの場合にエラーが発生していた問題を修正しました。
* (Windows, MacOS, WebGL) Log&Crashサーバーへのログ送信時、logTypeを設定してもLog&CrashページでlogTypeが"NORMAL"と表示される問題を修正しました。

<a id="813-2026-05-27-platform-specific-changes"></a>
#### プラットフォーム別の変更点
* [Gamebase Android SDK 2.80.2](./release-notes-android/#2-80-2-2026-04-28)
* [Gamebase iOS SDK 2.81.3](./release-notes-ios/#2-81-3-2026-05-27)
