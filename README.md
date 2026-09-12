[![Swift Version][swift-image]][swift-url]
![Platform](https://img.shields.io/badge/iOS-15.6%2B-blue)

# Smart City: Edinburgh
<br />
<p align="center">
  <a href="https://canduru.net">
    <img src="https://i.ibb.co/rHFr92y/Original-resized.png" alt="Logo" width="221" height="90">
    <img src="https://user-images.githubusercontent.com/73294429/186247733-fef260b6-0d34-4123-a54e-86eb9a8217fa.png" alt="Logo" width="221" height="90">
  </a>
  <p align="center">
    An Edinburgh transport app built with Swift and UIKit. It supports maps, transit data, Firebase accounts, and NFC tag identifiers. Live transit features require an available data provider.
  </p>
</p>

<p align="center">
    <img src= "https://media.giphy.com/media/MhA5ZFImHOKE7Ji04H/giphy.gif" width="400" >
</p>

## Features

- Map browsing and place search.
- Live bus positions, stop search, and journey planning when the configured transit API is available.
- Firebase email/password accounts and personal information.
- NFC tag identifier scanning on supported physical iPhones. A tag identifier is not a bank card number or proof of a transport balance.

## Requirements

- iOS 15.6 or later.
- Xcode 26.2 or later. Verified with the installed Xcode 27.0 (27A5194q) and iOS 27.0 (24A5355p) runtime.
- CocoaPods 1.16.2 and a current Ruby installation.
- A physical iPhone with NFC capability and appropriate signing entitlements for NFC verification.

## Installation

CocoaPods remains the app's dependency manager. The root Swift package runs small calculation tests only.

```sh
pod install --project-directory=/absolute/path/to/Asis
open /absolute/path/to/Asis/Asis.xcworkspace
```

Open the workspace rather than the project. The committed Podfile.lock records the exact dependency versions. Use `pod install` for repeatable setup; use `pod update` only for an intentional dependency upgrade.

Select the Asis scheme and an installed iPhone simulator. For a physical device, select your development team in Signing & Capabilities and enable NFC Tag Reading for your app identifier.

## Service configuration and limits

The app's original `https://tfe-opendata.com/api/v1/` endpoint returned HTTP 522 during the September 12, 2026 compatibility check. Live vehicles, the complete stop list, and in-app timetables cannot be verified while that service is unavailable. Failed requests now show an unavailable state and allow retry. Journey failures offer Apple Maps transit directions.

The council announced the [Edinburgh Travel Tracker API](https://www.edinburgh.gov.uk/news/article/14063/transport-trackers-are-go-in-edinburgh). Its [current website](https://www.edinburghtraveltracker.com/#/liveDepartures) includes API Keys and Contact Us controls. A working replacement API contract and access still need to be obtained before migration.

The `TransitAPIBaseURL` key in Asis/Info.plist selects the HTTPS API base URL. A replacement must implement the existing stops, vehicle_locations, services, and stoptostop-timetable response contracts. Changing a URL alone does not adapt an unrelated provider.

For accounts, obtain GoogleService-Info.plist from your own Firebase project and keep it at Asis/GoogleService-Info.plist. This file is ignored by Git. The configuration is copied into the app only when present; without it, maps remain usable and account features display an unavailable state. The build setting `FIREBASE_CONFIG_PATH` can override the source path for CI or configuration-free testing. Enable Email/Password authentication and Cloud Firestore. Never commit credentials or use permissive Firestore rules to bypass a permissions error. Profile access expects an exact `uid` field matching the authenticated Firebase UID. Older randomly named profile documents remain supported. Duplicate matching profiles are treated as an error.

NFC scanning saves the tag's hexadecimal identifier. Earlier code generated random balances; this version never generates or displays those values as real balances. An authoritative operator integration is needed for actual balance information. Existing stored balance fields are left intact.

Email changes require verification of the new address. Profile, password, and email changes are separate backend operations; a failure message tells the user to review potentially saved changes.

Firebase is ending new CocoaPods releases in October 2026. Existing versions remain installable. Plan a separate migration to Swift Package Manager for future Firebase updates. See [Firebase's migration notice](https://firebase.google.com/docs/ios/cocoapods-deprecation) and [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/).

## Verification

Run the pure Swift regression tests:

```sh
swift test --package-path /absolute/path/to/Asis
```

Build without a signing account:

```sh
xcodebuild -workspace /absolute/path/to/Asis/Asis.xcworkspace \
  -scheme Asis -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /absolute/path/to/Asis/DerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

Run the app unit tests and screen-flow tests against an installed simulator:

```sh
xcodebuild -workspace /absolute/path/to/Asis/Asis.xcworkspace \
  -scheme Asis -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_UDID' \
  -derivedDataPath /absolute/path/to/Asis/DerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

Verified on September 12, 2026:

- 7 pure Swift tests: NFC identifier padding, malformed times, midnight, and Edinburgh winter/summer time.
- 6 app tests: HTTP failure, malformed JSON, invalid coordinates, host validation, empty timetables, and card layout at two widths.
- 4 iPhone screen-flow tests: navigation during transit failure, signed-out card handling, password-reset field validation, share-sheet presentation, and mismatched sign-up passwords.
- 3 iPad screen-flow tests passed in the app's existing iPhone compatibility mode. This is not a native iPad layout.
- Configuration-free startup and tab navigation passed with `FIREBASE_CONFIG_PATH` set to a nonexistent file inside the build directory.
- Simulator Debug and unsigned device Release builds passed. Third-party CocoaPods build-script warnings remain.

Test output and screenshots are saved locally under the ignored `build/` directory, including `FinalTests.xcresult`, `iPadFlows2.xcresult`, `NoFirebase.xcresult`, and `device-final.log`. The UI tests use an English, signed-out simulator and never complete account creation or send a password-reset email.

Manual checks: launch with location denied, switch through all tabs, retry transit data, search places, cancel a journey, open stop directions, reset a password with the email field empty, and open or dismiss account screens. NFC requires a physical iPhone. Real authentication, profile updates, backend security rules, and live timetable accuracy require the owner's configured services and test account.

## Original application screenshots (2022)

<p align="center">
<img src= "https://user-images.githubusercontent.com/73294429/186215025-a5e40cdb-2bf1-48dd-9b70-35745e120e63.png" width="400" >
<img src= "https://user-images.githubusercontent.com/73294429/186215478-dacfe7a4-2358-4831-b046-50578876b6d2.png" width="400" >
</p>

<p align="center">
<img src= "https://user-images.githubusercontent.com/73294429/186215800-73a818a7-8d0a-42cd-b352-35985c415794.png" width="400" >
<img src= "https://user-images.githubusercontent.com/73294429/186215859-0ef4b070-48e7-4876-a93c-223eb37a8b25.png" width="400" >
</p>

<p align="center">
<img src= "https://user-images.githubusercontent.com/73294429/186249659-aeace6de-b1a3-4542-beea-f927abb4a843.png" width="400" >
<img src= "https://user-images.githubusercontent.com/73294429/186215775-8fd31174-4461-49c3-8d89-c1f399e91277.png" width="400" >
</p>

## Contribute

I would like to thank **The Transport for Edinburgh Open Data API** for its contribution to the project.

## Meta

Can Duru: canduru2004@gmail.com, can@canduru.net


[https://github.com/CanDuru4](https://github.com/CanDuru4)

[swift-image]:https://img.shields.io/badge/swift-5.0-orange.svg
[swift-url]: https://swift.org/
