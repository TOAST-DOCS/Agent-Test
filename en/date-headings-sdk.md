<!-- machine_translated: true -->

<!-- pre-align:aligned sig=a0bb857088ed -->

<a id="nhn-cloud-sdk-user-guide-release-notes-ios"></a>
## NHN Cloud > SDK User Guide > Release Notes > iOS { #nhn-cloud-sdk-user-guide-release-notes-ios }

<a id="110-2026-10-14"></a>
## 1.11.0(October 14, 2026) { #110-2026-10-14 }

<a id="110-2026-10-14-nhn-cloud-push"></a>
### NHN Cloud Push { #110-2026-10-14-nhn-cloud-push }

<a id="110-2026-10-14-nhn-cloud-push-bugfix"></a>
#### Bug Fixes
* Fixed Push Token Registration Failure in Specific Situations.

<a id="100-2026-09-15"></a>
## 1.10.0 (September 15, 2026) { #100-2026-09-15 }

<a id="100-2026-09-15-nhn-cloud-logger"></a>
### NHN Cloud Logger { #100-2026-09-15-nhn-cloud-logger }

<a id="100-2026-09-15-nhn-cloud-logger-improved"></a>
#### Feature Updates

* Changed Log & Crash Search API Domain
    * The log collection API domain changed from api-logncrash.cloud.toast.com to api-logncrash.nhncloudservice.com.
    * The settings API domain changed from setting-logncrash.cloud.toast.com to api-setting-logncrash.nhncloudservice.com.

<a id="100-2026-09-15-symboluploaderv005"></a>
### SymbolUploader(v0.0.5) { #100-2026-09-15-symboluploaderv005 }

<a id="100-2026-09-15-symboluploaderv005-added-features"></a>
#### Added Features

* Applied Log & Crash Search Symbol API v3
    * Starting from v0.0.5, User Access Token authentication is required.
      * Authentication using appKey alone is not supported; User Access Token authentication is required.
      * You can configure a User Access Token directly or have one issued automatically by using a User Access Key and Secret Access Key.
      * For more information, refer to [Apply NHN Cloud Symbol Uploader](https://docs.nhncloud.com/en/nhncloud-sdk/en/log-collector-ios/#apply-nhn-cloud-symbol-uploader).

<a id="100-2026-09-15-nhn-cloud-push"></a>
### NHN Cloud Push { #100-2026-09-15-nhn-cloud-push }

<a id="100-2026-09-15-nhn-cloud-push-improved"></a>
#### Feature Updates

* Changed Push API domain
    * The token API and user tag API domain has been changed from api-push.cloud.toast.com to push.api.nhncloudservice.com.
* Improved Notification Hub metrics transfer method
    * Improved so that the same metrics are not counted twice even if metrics transfer is retried.

<a id="100-2026-09-15-nhn-cloud-push-bugfix"></a>
#### Bug Fixes

* Fixed an issue where Notification Hub token updates failed
    * Fixed an issue where token registration always failed after changing the user ID.

<a id="100-2026-09-15-nhn-cloud-ocr"></a>
### NHN Cloud OCR { #100-2026-09-15-nhn-cloud-ocr }

<a id="100-2026-09-15-nhn-cloud-ocr-improved"></a>
#### Feature Updates

* Changed OCR API Domain
    * The OCR API domain has been changed from ocr.api.nhncloudservice.com to api-ocr.nhncloudservice.com.
* Improved error delivery for PublicKey acquisition failures
    * Improved the system to deliver PublicKey acquisition failure errors that occur before Delegate registration after Delegate registration is complete.

<a id="100-2026-09-15-nhn-cloud-ocr-bugfix"></a>
#### Bug Fixes

* Fixed an issue where the Default UI icon aspect ratio was distorted

<a id="90-2025-04-29"></a>
## 1.9.0 (April 29, 2025) { #90-2025-04-29 }

<a id="90-2025-04-29-nhn-cloud-push"></a>
### NHN Cloud Push { #90-2025-04-29-nhn-cloud-push }

<a id="90-2025-04-29-nhn-cloud-push-added-features"></a>
#### Added Features

* Added Notification Hub
    * You can use Notification Hub in the NHNCloudPush SDK.
    * You can use it by setting the `NHNCloudPushServiceTypeNotificationHub` value for the `serviceType` property of `NHNCloudPushConfiguration`.
