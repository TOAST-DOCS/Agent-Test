<!-- machine_translated: true -->

<!-- pre-align:aligned sig=602ad029c65d -->

<a id="game-gamebase-release-notes-unity"></a>
## Game > Gamebase > Release Notes > Unity { #game-gamebase-release-notes-unity }

<a id="2-83-0-2026-10-13"></a>
### 2.83.0 (October 13, 2026) { #2-83-0-2026-10-13 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.83.0/GamebaseSDK-Unity.zip)

<a id="830-2026-10-13-added-features"></a>
#### Added Features
* (Windows, macOS) Added support for Predefined Custom Scheme in WebView.
* (Windows, macOS) Added a View Details button to display the maintenance details page in the maintenance popup.
* Added the extras field to GamebaseResponse.Purchase.PurchasableReceipt.

<a id="830-2026-10-13-feature-updates"></a>
#### Feature Updates
* Added support for Unity Editor's Fast Enter Play Mode environment.
* GamebaseResponse.Event.PurchasableReceipt has been deprecated. Use GamebaseResponse.Purchase.PurchasableReceipt instead.

<a id="830-2026-10-13-bug-fixes"></a>
#### Bug Fixes
* (Android, iOS) Fixed an issue where some receipt information was missing in the PURCHASE_UPDATED event.
* (Windows, macOS, WebGL) Fixed an issue where login could not be retried in certain circumstances.
* (WebGL) Fixed an issue where restarting the app after switching accounts using ChangeLogin would log in with the previous account.
* (macOS) Fixed an issue where WebView was not displayed correctly in the Apple Silicon environment.
* (Windows, macOS) Fixed an issue where a crash occurred when exiting the app after using WebView.
* (Windows, macOS) Fixed an issue where the gamebase://openbrowser and gamebase://dismiss schemes were processed multiple times in WebView.

<a id="830-2026-10-13-platform-specific-changes"></a>
#### Platform-Specific Changes
* [Gamebase Android SDK 2.83.0](./release-notes-android/#2-83-0-2026-09-17)
* [Gamebase iOS SDK 2.82.1](./release-notes-ios/#2-82-1-2026-08-25)

<a id="2-82-0-2026-08-11"></a>
### 2.82.0 (2026. 08. 11.) { #2-82-0-2026-08-11 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.82.0/GamebaseSDK-Unity.zip)

<a id="820-2026-08-11-feature-updates"></a>
#### Feature Updates
* (Android, iOS) Improved the validation logic for invalid data.

<a id="820-2026-08-11-bug-fixes"></a>
#### Bug Fixes
* (Windows, macOS) Fixed an issue where the gamebase://openbrowser scheme is not normally processed in the WebView.

<a id="820-2026-08-11-platform-specific-changes"></a>
#### Platform-specific Changes
* [Gamebase Android SDK 2.82.0](./release-notes-android/#2-82-0-2026-07-28)
* [Gamebase iOS SDK 2.82.0](./release-notes-ios/#2-82-0-2026-07-28)

<a id="820-2026-08-11-setting-tool-v301"></a>
#### Setting Tool (v3.0.1)

* Added support for installing a dedicated adapter for the WebGL platform.

<a id="2-81-4-2026-07-14"></a>
### 2.81.4 (2026. 07. 14.) { #2-81-4-2026-07-14 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.81.4/GamebaseSDK-Unity.zip)

<a id="814-2026-07-14-bug-fixes"></a>
#### Bug Fixes
* (Windows, macOS) Fixed an intermittent error that occurred when attempting to reconnect via WebSocket in an unstable network environment.

<a id="814-2026-07-14-feature-updates"></a>
#### Feature Updates
* Applied Assembly Definition (.asmdef) on the Gamebase SDK.

<a id="814-2026-07-14-platform-specific-changes"></a>
#### Platform-specific Changes
* [Gamebase Android SDK 2.81.0](./release-notes-android/#2-81-0-2026-06-23)
* [Gamebase iOS SDK 2.81.3](./release-notes-ios/#2-81-3-2026-05-27)

<a id="2-81-3-2026-05-27"></a>
### 2.81.3 (2026. 05. 27.) { #2-81-3-2026-05-27 }
[SDK Download](https://static.toastoven.net/toastcloud/sdk_download/gamebase/v2.81.3/GamebaseSDK-Unity.zip)

<a id="813-2026-05-27-bug-fixes"></a>
#### Bug Fixes
* (Windows, MacOS, WebGL) Fixed an issue where an error occurred when the value of a key-value pair entered in userFields was null when sending logs to the Log&Crash server.
* (Windows, MacOS, WebGL) Fixed an issue where logType was displayed as "NORMAL" on the Log&Crash page even when logType was set when sending logs to the Log&Crash server.

<a id="813-2026-05-27-platform-specific-changes"></a>
#### Platform-specific Changes
* [Gamebase Android SDK 2.80.2](./release-notes-android/#2-80-2-2026-04-28)
* [Gamebase iOS SDK 2.81.3](./release-notes-ios/#2-81-3-2026-05-27)
