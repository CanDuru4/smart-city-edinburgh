# Smart City: Edinburgh

iOS public-transport app for Edinburgh (map + place search, live buses, stops, journey planning, Firebase accounts, NFC tag scanning). Original 2022 app, revived for current Xcode/iOS in September 2026; now maintained occasionally. Swift 5 + UIKit (programmatic, no main storyboard), MapKit, CoreLocation, CoreNFC, Alamofire, Firebase (Auth, Firestore, Analytics), Core Data, CocoaPods. Public repo, MIT.

The Xcode project, workspace, app target and scheme are all named `Asis` (the original working title). Keep that name; do not rename targets.

## Repo map

- `Asis/` - app sources, grouped by screen/feature:
  - `Home/` map screen, floating panel, route search; `BusStops/`; `Card/` (NFC reader + `CreditCardView/`); `Settings/` (auth, `Login/`, `Sign Up/`, `Menu/`); `SideMenu/`
  - `Data/` - `GetBaseData.swift` (legacy Alamofire transit client), `JourneoClient.swift` (isolated NOVUS-RT client), `JourneoModels.swift` (guide response models), Codable response models (`*DataSetup.swift`, `ServiceData.swift`), `UserProfileStore.swift` (Firestore profiles)
  - `Domain/` - pure logic (`TransitTime`, `CardIdentifier`, `JourneoConfiguration`, `JourneoRequests`); also compiled by the root `Package.swift` as `AsisLogic`
  - `Helper/` - reachability, location, annotations, loading UI, `AppFeedback`
  - `Translation/<lang>.lproj/Localizable.strings` - en, de, es, fr, ru, tr, zh-Hans
  - `Info.plist` (holds `TransitAPIBaseURL`), `Asis.entitlements`, `Asis.xcdatamodeld`
- `Tests/AsisLogicTests/` - SwiftPM tests for `Asis/Domain`
- `Tests/AsisTests/` - app unit tests (`@testable import Asis`), `Tests/AsisUITests/` - screen-flow UI tests
- `Package.swift` - pure-logic test package only; it is not how the app is built
- `Podfile`, `Podfile.lock` (committed); `Pods/` is git-ignored
- `docs/OPERATIONS.md` - transit provider status, Firebase rules expectations, NFC, dated verification record; `design-assets/` - brand and design assets (`logo/`, `banner/`, `screenshots/` incl. README images)

## Commands

Run from the repo root (or pass `--package-path` / an absolute `-workspace` path).

```bash
pod install                      # setup; use pod update only for an intentional upgrade
swift test                       # pure Domain and Journeo contract tests on macOS
xcodebuild -workspace Asis.xcworkspace -scheme Asis \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
xcodebuild -workspace Asis.xcworkspace -scheme Asis \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO test   # AsisTests + AsisUITests
```

- Always open/build `Asis.xcworkspace`, never the bare `.xcodeproj` (CocoaPods).
- No CI and no automated release; archives are made from Xcode. Nothing to deploy.
- `DerivedData/`, `build/`, `.build/`, `.swiftpm/` are git-ignored build output.

## Configuration and secrets

- `Asis/GoogleService-Info.plist` is git-ignored and must never be committed. A build phase copies it into the app only if present; the `FIREBASE_CONFIG_PATH` build setting overrides the source path (point it at a nonexistent file for configuration-free runs). Without it, maps work and account features show an unavailable state.
- `TransitAPIBaseURL` in `Asis/Info.plist` is the transit API root; `GetBaseData` rejects non-HTTPS URLs.
- `Asis/Keys.plist` is git-ignored and must never be committed. Copy `Asis/Keys.example.plist` and supply portal-verified `JourneoAPIBaseURL`, `JourneoAPIKeyHeaderName`, and `JourneoAPIKey`; omit `JourneoAPIKeySecondary` if unused. The optional build phase copies it only when present and removes a stale bundled copy otherwise. `JOURNEO_KEYS_PATH` overrides the source path. The Foundation-only resolver fails closed on missing, blank, or invalid configuration, with no legacy URL fallback. Descriptions redact configuration values.
- Journeo request contracts come from the linked guide in `docs/OPERATIONS.md`. The base URL and header name await portal verification. No UI or legacy contract integration is present; do not switch `TransitAPIBaseURL` to Journeo.
- Never loosen Firestore rules to get past a permissions error. Profiles are matched by an exact `uid` field; legacy randomly named profile docs must keep working; duplicate matches are an error.

## Gotchas

- The Transport for Edinburgh open-data API is closed, so live vehicles, full stop list and timetables are expected to fail at runtime. A replacement must implement the existing `stops`, `vehicle_locations`, `services` and `stoptostop-timetable` response contracts; changing the URL alone does not adapt a different provider. Failure paths (unavailable state, retry, Apple Maps fallback) are intended behavior.
- NFC saves only the tag's hex identifier. Never generate or display balances as if real; leave existing stored balance fields intact.
- `Asis/Data/JourneyTımeDataSetup.swift` contains a Turkish dotless `ı` in its name; reference it carefully (NFC/NFD) and do not "fix" it without updating the Xcode project.
- New Swift files must be added to `Asis.xcodeproj/project.pbxproj` target membership; logic meant for `swift test` goes in `Asis/Domain/` and must stay free of UIKit/Firebase imports.
- Firebase is ending new CocoaPods releases in October 2026; an SPM migration is a planned, separate piece of work. iPad runs in iPhone compatibility mode only.

## Conventions

- Swift `///` doc comments with `- Parameters:`, `- Returns:`, `Example:` on public-facing types and methods.
- Network callbacks always complete on the main queue, including failures; tests inject an Alamofire `Session` with a stub `URLProtocol` (see `Tests/AsisTests/TransitClientTests.swift`).
- User-facing strings go through `Localizable.strings` in all seven languages.
- UI tests run signed-out in English and must never create accounts or send password-reset emails.

## Validation placement and reuse (owner update 2026-10-26)

- Follow the global Claude/Codex test policy and `~/Developer/personal/mac-mini/validation-economy/README.md` and `COVERAGE.md`. Focus first; full coverage only when the changed inputs require it. Docs-only policy edits need no application suite or deploy.
- Use `~/Developer/personal/mac-mini/validation-economy/remote-run.py` as the first choice for compatible heavy committed-source Python/Node checks. It defaults to `gaming-pc` and handles connection and bounded Wake-on-LAN automatically; call it directly without a separate online check or asking the owner each time. Match the pinned runtime and locked dependencies, bound actual workers, and preserve repo data-export restrictions. Never export credentials, production data, signing keys or uncommitted work.
- The PC pool shares eight CPU slots and 24 GiB across isolated jobs with zero test swap; retain automatic job cleanup, the 8 GiB package-cache budget and 128 GiB virtual-disk cap. Brain is an explicit secondary route (`--runner brain`) when compatible, capped at two CPUs and 4 GiB together. If the PC remains unavailable after bounded wake/connect, report the blocker; never silently start the same work on the Mini or replay an uncertain submitted job.
- Xcode, Swift, simulator, signing and device checks stay on the Mini. The PC Linux runner has no Apple toolchain; only compatible ancillary Python/Node checks are eligible.
- For work that must run on the Mini: manual heavy commands use `repo-run.py --repo <absolute checkout> --profile <profile> -- <command>` from the shared helper; choose from native for the actual tool. Tiny syntax checks need no reservation. Bound tool workers and reserve separate heavy phases.
- Reuse only supported receipts with matching source, coverage, dependencies, runtime/platform and relevant environment. Preserve passed unaffected batches; count remote results only when the owning gate aggregates them. Receipts do not replace required build artifacts or OS/device/browser proof. Split or offload an impossible reservation instead of waiting indefinitely; only stop your own obsolete jobs. Existing gates need explicit remote routing and matching-result aggregation; this instruction does not automatically move unintegrated commands.
