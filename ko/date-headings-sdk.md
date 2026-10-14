<!-- pre-align:aligned sig=a0bb857088ed -->

<a id="nhn-cloud-sdk-user-guide-release-notes-ios"></a>
## NHN Cloud > SDK 사용 가이드 > 릴리스 노트 > iOS { #nhn-cloud-sdk-user-guide-release-notes-ios }

<a id="110-2026-10-14"></a>
## 1.11.0(2026. 10. 14.) { #110-2026-10-14 }

<a id="110-2026-10-14-nhn-cloud-push"></a>
### NHN Cloud Push { #110-2026-10-14-nhn-cloud-push }

<a id="110-2026-10-14-nhn-cloud-push-bugfix"></a>
#### 버그 수정
* 특정 상황에서 푸시 토큰 등록이 실패하는 문제 수정

<a id="100-2026-09-15"></a>
## 1.10.0(2026. 09. 15.) { #100-2026-09-15 }

<a id="100-2026-09-15-nhn-cloud-logger"></a>
### NHN Cloud Logger { #100-2026-09-15-nhn-cloud-logger }

<a id="100-2026-09-15-nhn-cloud-logger-improved"></a>
#### 기능 개선/변경
* Log & Crash Search API 도메인 변경
    * 로그 수집 API 도메인이 api-logncrash.cloud.toast.com에서 api-logncrash.nhncloudservice.com으로 변경되었습니다.
    * 설정 API 도메인이 setting-logncrash.cloud.toast.com에서 api-setting-logncrash.nhncloudservice.com으로 변경되었습니다.

<a id="100-2026-09-15-symboluploaderv005"></a>
### SymbolUploader(v0.0.5) { #100-2026-09-15-symboluploaderv005 }

<a id="100-2026-09-15-symboluploaderv005-added-features"></a>
#### 신규 기능 추가     
* Log & Crash Search Symbol API v3 적용
    * v0.0.5부터 User Access Token 인증이 필요합니다. 
      * appKey 단독 인증을 사용할 수 없으며, User Access Token 인증이 필요합니다.
      * User Access Token을 직접 설정하거나 User Access Key와 Secret Access Key를 사용해 자동으로 발급받을 수 있습니다.
      * 자세한 사항은 [NHN Cloud Symbol Uploader 적용](https://docs.nhncloud.com/ko/nhncloud-sdk/ko/log-collector-ios/#apply-nhn-cloud-symbol-uploader)을 참고합니다.

<a id="100-2026-09-15-nhn-cloud-push"></a>
### NHN Cloud Push { #100-2026-09-15-nhn-cloud-push }

<a id="100-2026-09-15-nhn-cloud-push-improved"></a>
#### 기능 개선/변경
* Push API 도메인 변경
    * 토큰 API와 사용자 태그 API 도메인이 api-push.cloud.toast.com에서 push.api.nhncloudservice.com으로 변경되었습니다.
* Notification Hub 지표 전송 방식 개선
    * 지표 전송이 재시도되더라도 동일한 지표가 중복 집계되지 않도록 개선하였습니다.

<a id="100-2026-09-15-nhn-cloud-push-bugfix"></a>
#### 버그 수정
* Notification Hub 토큰 업데이트 실패 문제 수정
    * 사용자 ID를 변경한 뒤 토큰 등록이 항상 실패하던 문제를 수정하였습니다.

<a id="100-2026-09-15-nhn-cloud-ocr"></a>
### NHN Cloud OCR { #100-2026-09-15-nhn-cloud-ocr }

<a id="100-2026-09-15-nhn-cloud-ocr-improved"></a>
#### 기능 개선/변경
* OCR API 도메인 변경
    * OCR API 도메인이 ocr.api.nhncloudservice.com에서 api-ocr.nhncloudservice.com으로 변경되었습니다.
* PublicKey 획득 실패 오류 전달 개선
    * Delegate 등록 전에 발생한 PublicKey 획득 실패 오류를 Delegate 등록 이후 전달하도록 개선하였습니다.

<a id="100-2026-09-15-nhn-cloud-ocr-bugfix"></a>
#### 버그 수정
* Default UI 아이콘 비율이 왜곡되는 문제 수정

<a id="90-2025-04-29"></a>
## 1.9.0(2025. 04. 29.) { #90-2025-04-29 }

<a id="90-2025-04-29-nhn-cloud-push"></a>
### NHN Cloud Push { #90-2025-04-29-nhn-cloud-push }

<a id="90-2025-04-29-nhn-cloud-push-added-features"></a>
#### 신규 기능 추가 
* Notification Hub 지원 
    * NHNCloudPush SDK에서  Notification Hub를 이용할 수 있습니다.
    * NHNCloudPushConfiguration의 serviceType 프로퍼티에 NHNCloudPushServiceTypeNotificationHub 값을 설정하여 사용 가능합니다.
