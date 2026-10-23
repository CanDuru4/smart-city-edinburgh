# Operations notes

Service configuration, known backend limits and the dated verification record for Smart City: Edinburgh. The Xcode project, workspace and app target are named `Asis`. Setup and everyday test commands live in the [README](../README.md).

## Transit data provider

The app's original `https://tfe-opendata.com/api/v1/` endpoint returned HTTP 522 during the September 12, 2026 compatibility check. The owner confirmed that the old service is closed and has requested access to its replacement. Live vehicles, the complete stop list, and in-app timetables remain unavailable until a working replacement is integrated. Failed requests show an unavailable state and allow retry. Journey failures offer Apple Maps transit directions.

The council announced the [Edinburgh Travel Tracker API](https://www.edinburgh.gov.uk/news/article/14063/transport-trackers-are-go-in-edinburgh). Its [current website](https://www.edinburghtraveltracker.com/#/liveDepartures) includes API Keys and Contact Us controls. A working replacement API contract and access still need to be obtained before migration.

The `TransitAPIBaseURL` key in `Asis/Info.plist` selects the HTTPS API base URL. A replacement must implement the existing stops, vehicle_locations, services, and stoptostop-timetable response contracts. Changing a URL alone does not adapt an unrelated provider.

### NOVUS-RT / Journeo option

The isolated `JourneoClient` implements the five GET operations below from the [NOVUS-RT Open API guide](https://www.edinburghtraveltracker.com/resources/docs/open_api_guide.pdf), fetched and extracted on October 19, 2026. All paths are appended to the configured API root. This client is not wired into the UI or the legacy `stops`, `vehicle_locations`, `services`, or `stoptostop-timetable` contracts. `Asis/Info.plist` and its `TransitAPIBaseURL` remain unchanged.

The base URL and exact API-key header name are **pending portal verification** for product **NRT Open API Edinburgh CEC Bus tracker Open Interface**. Section 2 describes an access-token path generically; section 16.2 instead instructs consumers to use a supplied BaseURL and send User_Key as an HTTP header. It supplies neither a customer endpoint nor an unambiguous literal header name. Do not infer either value or append a credential to a URL.

| GET path | Required query parameters | Optional query parameters | Guide sections |
| --- | --- | --- | --- |
| `StopEvents` | Exactly one of `AtcoCode` or `SMSCode`, nonempty string identifier | `EventType`: `arrival` or `departure`; `Lookahead`: integer minutes, server default 60; `MaxEvents`: integer limit; `MinVisitsPerService`: integer minimum per service; `Ordering`: `SchArr`, `SchDep`, `RealArr`, `RelaDep`; `TimeFormat`: `UTC` or `Local` (server default `UTC`) | 3.1 to 3.3 |
| `StopDetails` | `atcoCode`: nonempty string ATCO identifier | None documented | 7.1 to 7.3 |
| `GetStops` | `date`: Gregorian `CCYY-MM-DD` | `FullDetails`: `true` or `false`, default false | 11.1 to 11.3 |
| `AreaSearch` | `ne_lat`, `ne_long`, `sw_lat`, `sw_long`: finite decimal degrees | None documented; no radius or result limit | 5.1 to 5.3 |
| `VehicleStatus` | `VehicleId`: nonempty string vehicle identifier | `TimeFormat`: `UTC` or `Local`, server default `UTC` | 4.1 to 4.3 |

Pending clarification from the portal or provider:

- Query-name casing differs between tables and examples: `AtcoCode` / `Atcocode`, `atcoCode` / `Atcocode`, and `date` / `Date`. Builders use the parameter-table spellings.
- The guide spells real departure ordering `RelaDep`. The typed enum preserves that spelling; acceptance by the live service is unverified.
- AreaSearch labels its corners top-left and bottom-right, but names them NE and SW and gives numbers consistent with NE/SW. Builders follow the names and example. They require north > south and east > west, reject antimeridian boxes, and validate latitude within -90 to 90 and longitude within -180 to 180.
- Numeric upper limits and zero-value semantics are unspecified. Builders require positive event windows and counts. No guessed limits or extra query parameters are added.
- The GetStops full-detail JSON shape is undocumented. Code-only responses use the documented `atcocodes` model; full-detail responses are returned as JSON-validated Data. The other four operations decode the sample envelopes. Production nullability and time formats still need verification against real responses.

Configuration lives only in git-ignored `Asis/Keys.plist`, optionally selected through `JOURNEO_KEYS_PATH`. The example contains four empty values. Fill all three required entries and either fill or remove the optional secondary entry. A present blank secondary entry fails closed too. The resolver trims whitespace, requires HTTPS and a host, rejects URL credentials/query/fragment, validates the header as an RFC 7230 token, and rejects transport-controlled header names (`Accept`, `Host`, `Content-Length`, `Content-Type`, `Connection`, `Transfer-Encoding`) that would conflict with request construction. Keys with embedded control characters are rejected. The client resolves configuration for each call, uses the primary key only, accepts HTTP 200 to 299, refuses redirects, and completes on the main queue, including failures and cancellation.

Portal login, subscription, credentials, and access requests are outside this repository. The owner or authorized Jarvis workflow must verify the product and store issued keys as `jarvis/JOURNEO_API_KEY` and `jarvis/JOURNEO_API_KEY_SECONDARY`. No portal actions or messages are performed by this worker. If access is unavailable, the API Keys form on [Edinburgh Travel Tracker](https://www.edinburghtraveltracker.com/) is the alternative; an authorized workflow may prepare an unsent request to `ccuk@trapezegroup.com` for owner approval.

## Firebase accounts

Obtain `GoogleService-Info.plist` from your own Firebase project and keep it at `Asis/GoogleService-Info.plist`. This file is ignored by Git. The configuration is copied into the app only when present; without it, maps remain usable and account features display an unavailable state. The build setting `FIREBASE_CONFIG_PATH` can override the source path for CI or configuration-free testing. Enable Email/Password authentication and Cloud Firestore. Never commit credentials or use permissive Firestore rules to bypass a permissions error. Profile access expects an exact `uid` field matching the authenticated Firebase UID. Older randomly named profile documents remain supported. Duplicate matching profiles are treated as an error.

Email changes require verification of the new address. Profile, password, and email changes are separate backend operations; a failure message tells the user to review potentially saved changes.

## NFC

NFC scanning saves the tag's hexadecimal identifier. Earlier code generated random balances; the current version never generates or displays those values as real balances. An authoritative operator integration is needed for actual balance information. Existing stored balance fields are left intact.

## CocoaPods and Firebase

Firebase is ending new CocoaPods releases in October 2026. Existing versions remain installable. Plan a separate migration to Swift Package Manager for future Firebase updates. See [Firebase's migration notice](https://firebase.google.com/docs/ios/cocoapods-deprecation) and [Apple SDK requirements](https://developer.apple.com/news/upcoming-requirements/).

## Journeo verification record (October 19, 2026)

This unattended worker used synthetic credentials and no portal account or device. No real Keys.plist or Firebase configuration was read or copied.

- `pod install` passed using CocoaPods 1.16.2 installed under ignored `build/`; `Podfile.lock` is unchanged.
- All 24 repository logic XCTest cases passed when compiled directly with `swiftc` and run with `xctest` on macOS: 17 Journeo cases plus the existing 7 domain cases.
- All 11 portable Journeo client tests passed through a direct macOS XCTest bundle using the installed Alamofire sources. These cover the configured header, sample response decoding, HTTP and JSON failures, invalid inputs, per-call configuration resolution, no-request resolver failure, cancellation, and refusal to follow redirects.
- The new Swift sources and tests compiled in Swift 5 mode. `plutil` and the Xcodeproj parser validated the project; source membership, Debug/Release settings, build-phase adjacency, and template exclusion from resources passed structural checks.
- The optional Journeo build script copied an empty template fixture and removed the stale bundled fixture when its input was absent.
- Plist syntax, all four empty example values, ignored Keys.plist, unignored example, no tracked Keys.plist, unchanged `TransitAPIBaseURL`, and the requested credential-pattern and whitespace scans passed.

Not verified in this run:

- `swift test` was attempted but blocked by nested sandbox and build-file access errors with Xcode 27.1. Direct XCTest results above do not claim that SwiftPM itself passed.
- `xcodebuild -list` and the simulator build were attempted, but Xcode did not recognize the workspace in this sandbox and CoreSimulator services were inaccessible. The workspace XML and project parsed separately. The full app build, simulator app/UI tests, and the new app-bundle `TransitAPIBaseURL` assertion remain unverified; the source plist equality check passed.
- Portal BaseURL/header verification, subscription and Jarvis secret storage, the owner-approved access-request artifact, and a live authenticated request were outside this worker's tools and authorization. No login, account changes, messages, or email occurred.
- Before merging, an authorized run must execute the normal README SwiftPM and iOS checks. The owner must verify the portal settings, provision local configuration, confirm a successful request and fail-closed removal of a value, and review the guide ambiguities above.

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
