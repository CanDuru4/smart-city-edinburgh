# Operations notes

Service configuration, known backend limits and the dated verification record for Smart City: Edinburgh. The Xcode project, workspace and app target are named `Asis`. Setup and everyday test commands live in the [README](../README.md).

## Transit data provider

The app's original `https://tfe-opendata.com/api/v1/` endpoint returned HTTP 522 during the September 12, 2026 compatibility check. The owner confirmed that the old service is closed and has requested access to its replacement. Live vehicles, the complete stop list, and in-app timetables remain unavailable until a working replacement is integrated. Failed requests show an unavailable state and allow retry. Journey failures offer Apple Maps transit directions.

The council announced the [Edinburgh Travel Tracker API](https://www.edinburgh.gov.uk/news/article/14063/transport-trackers-are-go-in-edinburgh). Its [current website](https://www.edinburghtraveltracker.com/#/liveDepartures) includes API Keys and Contact Us controls. A working replacement API contract and access still need to be obtained before migration.

The `TransitAPIBaseURL` key in `Asis/Info.plist` selects the HTTPS API base URL. A replacement must implement the existing stops, vehicle_locations, services, and stoptostop-timetable response contracts. Changing a URL alone does not adapt an unrelated provider.

## Firebase accounts

Obtain `GoogleService-Info.plist` from your own Firebase project and keep it at `Asis/GoogleService-Info.plist`. This file is ignored by Git. The configuration is copied into the app only when present; without it, maps remain usable and account features display an unavailable state. The build setting `FIREBASE_CONFIG_PATH` can override the source path for CI or configuration-free testing. Enable Email/Password authentication and Cloud Firestore. Never commit credentials or use permissive Firestore rules to bypass a permissions error. Profile access expects an exact `uid` field matching the authenticated Firebase UID. Older randomly named profile documents remain supported. Duplicate matching profiles are treated as an error.

Email changes require verification of the new address. Profile, password, and email changes are separate backend operations; a failure message tells the user to review potentially saved changes.

## NFC

NFC scanning saves the tag's hexadecimal identifier. Earlier code generated random balances; the current version never generates or displays those values as real balances. An authoritative operator integration is needed for actual balance information. Existing stored balance fields are left intact.

## CocoaPods and Firebase

Firebase is ending new CocoaPods releases in October 2026. Existing versions remain installable. Plan a separate migration to Swift Package Manager for future Firebase updates. See [Firebase's migration notice](https://firebase.google.com/docs/ios/cocoapods-deprecation) and [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/).

## Verification record (September 12, 2026)

Verified with Xcode 27.0 (27A5194q) and the iOS 27.0 (24A5355p) simulator runtime:

- 7 pure Swift tests: NFC identifier padding, malformed times, midnight, and Edinburgh winter/summer time.
- 6 app tests: HTTP failure, malformed JSON, invalid coordinates, host validation, empty timetables, and card layout at two widths.
- 4 iPhone screen-flow tests: navigation during transit failure, signed-out card handling, password-reset field validation, share-sheet presentation, and mismatched sign-up passwords.
- 3 iPad screen-flow tests passed in the app's existing iPhone compatibility mode. This is not a native iPad layout.
- Configuration-free startup and tab navigation passed with `FIREBASE_CONFIG_PATH` set to a nonexistent file inside the build directory.
- Simulator Debug and unsigned device Release builds passed. Third-party CocoaPods build-script warnings remain.

Test output and screenshots were saved locally under the ignored `build/` directory, including `FinalTests.xcresult`, `iPadFlows2.xcresult`, `NoFirebase.xcresult`, and `device-final.log`. The UI tests use an English, signed-out simulator and never complete account creation or send a password-reset email.

Manual checks: launch with location denied, switch through all tabs, retry transit data, search places, cancel a journey, open stop directions, reset a password with the email field empty, and open or dismiss account screens. NFC requires a physical iPhone. Real authentication, profile updates, backend security rules, and live timetable accuracy require the owner's configured services and test account.
