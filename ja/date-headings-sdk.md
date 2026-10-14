<!-- machine_translated: true -->

<!-- pre-align:aligned sig=a0bb857088ed -->

<a id="nhn-cloud-sdk-user-guide-release-notes-ios"></a>
## NHN Cloud > User Guide for SDK > Release Notes > iOS { #nhn-cloud-sdk-user-guide-release-notes-ios }

<a id="110-2026-10-14"></a>
## 1.11.0(2026. 10. 14.) { #110-2026-10-14 }

<a id="110-2026-10-14-nhn-cloud-push"></a>
### NHN Cloud Push { #110-2026-10-14-nhn-cloud-push }

<a id="110-2026-10-14-nhn-cloud-push-bugfix"></a>
#### バグ修正
* 特定の状況でプッシュトークン登録が失敗する問題を修正

<a id="100-2026-09-15"></a>
## 1.10.0(2026. 09. 15.) { #100-2026-09-15 }

<a id="100-2026-09-15-nhn-cloud-logger"></a>
### NHN Cloud Logger { #100-2026-09-15-nhn-cloud-logger }

<a id="100-2026-09-15-nhn-cloud-logger-improved"></a>
#### 機能改善/変更

* Log & Crash Search API ドメインの変更
    * ログ収集 API ドメインが api-logncrash.cloud.toast.com から api-logncrash.nhncloudservice.com に変更されました。
    * 設定 API ドメインが setting-logncrash.cloud.toast.com から api-setting-logncrash.nhncloudservice.com に変更されました。

<a id="100-2026-09-15-symboluploaderv005"></a>
### SymbolUploader(v0.0.5) { #100-2026-09-15-symboluploaderv005 }

<a id="100-2026-09-15-symboluploaderv005-added-features"></a>
#### 新規機能追加

* Log & Crash Search Symbol API v3 適用
    * v0.0.5 以降、User Access Token 認証が必要です。
      * appKey 単独認証は使用できません。User Access Token 認証が必要です。
      * User Access Token を直接設定するか、User Access Key と Secret Access Key を使用して自動で発行できます。
      * 詳細については、[NHN Cloud Symbol Uploader 適用](https://docs.nhncloud.com/ja/nhncloud-sdk/ja/log-collector-ios/#apply-nhn-cloud-symbol-uploader)を参照してください。

<a id="100-2026-09-15-nhn-cloud-push"></a>
### NHN Cloud Push { #100-2026-09-15-nhn-cloud-push }

<a id="100-2026-09-15-nhn-cloud-push-improved"></a>
#### 機能改善/変更

* Push API ドメインの変更
    * トークン API およびユーザータグ API のドメインが api-push.cloud.toast.com から push.api.nhncloudservice.com に変更されました。
* Notification Hub メトリクス転送方式の改善
    * メトリクスの転送がリトライされた場合でも、同一のメトリクスが重複集計されないように改善しました。

<a id="100-2026-09-15-nhn-cloud-push-bugfix"></a>
#### バグ修正

* Notification Hub トークン更新失敗の問題を修正
    * ユーザーIDを変更した後、トークン登録が常に失敗する問題を修正しました。

<a id="100-2026-09-15-nhn-cloud-ocr"></a>
### NHN Cloud OCR { #100-2026-09-15-nhn-cloud-ocr }

<a id="100-2026-09-15-nhn-cloud-ocr-improved"></a>
#### 機能改善/変更

* OCR API ドメインの変更
    * OCR API ドメインが ocr.api.nhncloudservice.com から api-ocr.nhncloudservice.com に変更されました。
* PublicKey 取得失敗エラーの通知改善
    * Delegate 登録前に発生した PublicKey 取得失敗エラーを、Delegate 登録後に通知するよう改善しました。

<a id="100-2026-09-15-nhn-cloud-ocr-bugfix"></a>
#### バグ修正

* Default UI アイコンの比率が歪む問題修正

<a id="90-2025-04-29"></a>
## 1.9.0(2025. 04. 29.) { #90-2025-04-29 }

<a id="90-2025-04-29-nhn-cloud-push"></a>
### NHN Cloud Push { #90-2025-04-29-nhn-cloud-push }

<a id="90-2025-04-29-nhn-cloud-push-added-features"></a>
#### 新規機能追加

* Notification Hub サポート
    * NHNCloudPush SDK で Notification Hub を利用できます。
    * NHNCloudPushConfiguration の serviceType プロパティに NHNCloudPushServiceTypeNotificationHub 値を設定して使用可能です。
