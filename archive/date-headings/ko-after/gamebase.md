<!-- pre-align:aligned sig=602ad029c65d -->

<a id="game-gamebase-release-notes-unity"></a>
## Game > Gamebase > 릴리스 노트 > Unity { #game-gamebase-release-notes-unity }

<a id="2-83-0-2026-10-13"></a>
### 2.83.0 (2026. 10. 13.) { #2-83-0-2026-10-13 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.83.0/GamebaseSDK-Unity.zip)

<a id="830-2026-10-13-added-features"></a>
#### 기능 추가
* (Windows, macOS) 웹뷰에서 Predefined Custom Scheme을 지원합니다.
* (Windows, macOS) 점검 팝업에 점검 상세 페이지를 표시하는 자세히 보기 버튼을 추가했습니다.
* GamebaseResponse.Purchase.PurchasableReceipt에 extras 필드를 추가했습니다.

<a id="830-2026-10-13-feature-updates"></a>
#### 기능 개선/변경
* Unity 에디터의 빠른 플레이 모드 진입(Fast Enter Play Mode) 환경을 지원합니다.
* GamebaseResponse.Event.PurchasableReceipt를 Deprecated 처리했습니다. GamebaseResponse.Purchase.PurchasableReceipt를 사용하세요.

<a id="830-2026-10-13-bug-fixes"></a>
#### 버그 수정
* (Android, iOS) PURCHASE_UPDATED 이벤트의 영수증 정보 일부가 누락되는 문제를 수정했습니다.
* (Windows, macOS, WebGL) 특정 상황에서 로그인을 다시 시도할 수 없는 문제를 수정했습니다.
* (WebGL) ChangeLogin으로 계정 전환 후 앱을 재시작하면 전환 전 계정으로 로그인되는 문제를 수정했습니다.
* (macOS) Apple Silicon 환경에서 웹뷰가 정상적으로 표시되지 않는 문제를 수정했습니다.
* (Windows, macOS) 웹뷰를 사용한 후 앱을 종료하면 크래시가 발생하는 문제를 수정했습니다.
* (Windows, macOS) 웹뷰에서 gamebase://openbrowser, gamebase://dismiss 스킴이 중복으로 처리되는 문제를 수정했습니다.

<a id="830-2026-10-13-platform-specific-changes"></a>
#### 플랫폼별 변경 사항
* [Gamebase Android SDK 2.83.0](./release-notes-android/#2-83-0-2026-09-17)
* [Gamebase iOS SDK 2.82.1](./release-notes-ios/#2-82-1-2026-08-25)

<a id="2-82-0-2026-08-11"></a>
### 2.82.0 (2026. 08. 11.) { #2-82-0-2026-08-11 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.82.0/GamebaseSDK-Unity.zip)

<a id="820-2026-08-11-feature-updates"></a>
#### 기능 개선/변경
* (Android, iOS) 유효하지 않은 데이터에 대한 검증 로직을 개선했습니다.

<a id="820-2026-08-11-bug-fixes"></a>
#### 버그 수정
* (Windows, macOS) 웹뷰에서 gamebase://openbrowser 스킴이 정상적으로 처리되지 않는 문제를 수정했습니다.

<a id="820-2026-08-11-platform-specific-changes"></a>
#### 플랫폼별 변경 사항
* [Gamebase Android SDK 2.82.0](./release-notes-android/#2-82-0-2026-07-28)
* [Gamebase iOS SDK 2.82.0](./release-notes-ios/#2-82-0-2026-07-28)

<a id="820-2026-08-11-setting-tool-v301"></a>
#### Setting Tool (v3.0.1)

* WebGL 플랫폼 전용 어댑터를 설치할 수 있습니다.

<a id="2-81-4-2026-07-14"></a>
### 2.81.4 (2026. 07. 14.) { #2-81-4-2026-07-14 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.81.4/GamebaseSDK-Unity.zip)

<a id="814-2026-07-14-bug-fixes"></a>
#### 버그 수정
* (Windows, macOS) 불안정한 네트워크 환경에서 Websocket 재연결을 시도할 때 간헐적으로 오류가 발생하는 문제를 수정했습니다.

<a id="814-2026-07-14-feature-updates"></a>
#### 기능 개선
* Gamebase SDK에 Assembly Definition(.asmdef)을 적용했습니다.

<a id="814-2026-07-14-platform-specific-changes"></a>
#### 플랫폼별 변경 사항
* [Gamebase Android SDK 2.81.0](./release-notes-android/#2-81-0-2026-06-23)
* [Gamebase iOS SDK 2.81.3](./release-notes-ios/#2-81-3-2026-05-27)

<a id="2-81-3-2026-05-27"></a>
### 2.81.3 (2026. 05. 27.) { #2-81-3-2026-05-27 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.81.3/GamebaseSDK-Unity.zip)

<a id="813-2026-05-27-bug-fixes"></a>
#### 버그 수정
* (Windows, macOS, WebGL) Log & Crash Search 서버로 로그 전송 시 userFields에 입력하는 키값 쌍의 값이 null인 경우 오류가 발생하던 문제를 수정했습니다.
* (Windows, macOS, WebGL) Log & Crash Search 서버로 로그 전송 시 logType을 설정해도 Log & Crash Search 페이지에서 logType이 "NORMAL"로 표시되는 문제를 수정했습니다.

<a id="813-2026-05-27-platform-specific-changes"></a>
#### 플랫폼별 변경 사항
* [Gamebase Android SDK 2.80.2](./release-notes-android/#2-80-2-2026-04-28)
* [Gamebase iOS SDK 2.81.3](./release-notes-ios/#2-81-3-2026-05-27)
