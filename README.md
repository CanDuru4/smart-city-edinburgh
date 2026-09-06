<p align="center">
  <a href="https://canduru.net">
    <img src="docs/assets/canduru-banner.png" alt="Can Duru" width="221" height="80">
  </a>
  <img src="docs/assets/app-logo.png" alt="Smart City: Edinburgh logo" width="221" height="90">
</p>

<h1 align="center">Smart City: Edinburgh</h1>

<p align="center">
  <a href="https://swift.org"><img src="https://img.shields.io/badge/swift-5.0-orange.svg" alt="Swift 5.0"></a>
  <img src="https://img.shields.io/badge/platform-iOS%2015.6%2B-lightgrey.svg" alt="Platform iOS 15.6+">
  <img src="https://img.shields.io/badge/Xcode-13.4%2B-blue.svg" alt="Xcode 13.4+">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License"></a>
</p>

<p align="center">
  A native iOS app for getting around Edinburgh on public transport. It plots live bus
  positions on a map from the <b>Transport for Edinburgh Open Data API</b>, lets you browse and
  search every stop in the city, builds a route between two places, and stores your travel card
  and profile in Firebase. Built for riders and visitors who want the live picture of the network
  in one place, and for iOS developers who want a compact UIKit + MapKit + Firebase reference app.
</p>

<p align="center">
  <img src="docs/assets/demo.gif" alt="App demo" width="300">
</p>

> The Xcode project, workspace and app target are still named **Asis**, the project's original
> working title. Only the repository and the product name were renamed to *Smart City: Edinburgh*.

## Features

- [x] Live bus locations on a MapKit map, refreshed every 15 seconds
- [x] Every Transport for Edinburgh stop, browsable and searchable
- [x] Departure times and service details for a selected stop or bus
- [x] Search for a destination and draw a public-transport route as a polyline
- [x] Travel card added by NFC tag reading (CoreNFC), with balance shown on a custom card view
- [x] Email sign-up / sign-in and profile editing backed by Firebase Auth and Firestore
- [x] Side menu, FAQ / contact page and an in-app language picker
- [x] Localised into 7 languages: English, German, Spanish, French, Russian, Turkish and Chinese (Simplified)

## Tech stack

| Layer | What is used |
| --- | --- |
| Language / UI | Swift 5, UIKit (programmatic layout, no main storyboard) |
| Maps & location | MapKit, CoreLocation |
| Hardware | CoreNFC (travel-card reading) |
| Networking | Alamofire, `JSONDecoder` models over the TfE Open Data API |
| Backend | Firebase Auth, Cloud Firestore, Realtime Database, Analytics |
| Local storage | Core Data (`Asis.xcdatamodeld`) |
| UI components | SideMenu, FloatingPanel, DropDown |
| Dependencies | CocoaPods 1.16.2 |

Data source: `https://tfe-opendata.com/api/v1/` — endpoints `stops`, `vehicle_locations`,
journey timetables and service details. The API needs no key.

## Requirements

- iOS 15.6 or later (the Pods are built against an iOS 14.0 deployment target)
- Xcode 13.4.1 or newer
- CocoaPods 1.16.2 or newer
- A Firebase project with Auth (email/password), Cloud Firestore and Realtime Database enabled
- A physical iPhone for the card feature — CoreNFC does not work in the Simulator

## Getting started

```bash
git clone https://github.com/CanDuru4/Smart-City-Edinburgh.git
cd Smart-City-Edinburgh
pod install
open Asis.xcworkspace
```

Then select the **Asis** scheme and run. Always open the `.xcworkspace`, not the `.xcodeproj` —
the project builds through CocoaPods.

### Firebase configuration

No credentials are committed to this repository. Before the first run, add your own:

| File | Where it goes | What it is |
| --- | --- | --- |
| `GoogleService-Info.plist` | `Asis/` | Downloaded from the Firebase console for your iOS app. Already referenced by the Xcode project and git-ignored. |
| `Keys.plist` | `Asis/` | Optional. Git-ignored slot for any local API keys you add; the app as published needs none. |

`FirebaseApp.configure()` runs in `AppDelegate` at launch, so a missing
`GoogleService-Info.plist` will crash the app on start.

The app also asks for two runtime permissions, declared in `Asis/Info.plist`:
`NSLocationAlwaysAndWhenInUseUsageDescription` and `NFCReaderUsageDescription`.

## Project structure

```
Asis/
├── AppDelegate.swift, SceneDelegate.swift, TabBarViewController.swift
├── Home/          Map screen, floating panel, route search
├── BusStops/      Stop list and stop detail cells
├── Card/          NFC card reader and the custom credit-card view
├── Settings/      Auth (login / sign up), personal info, FAQ
├── SideMenu/      Side menu, all-stops list, language picker
├── Data/          API client + Codable models (stops, buses, journeys, services)
├── Helper/        Network reachability, location manager, annotations, loading UI
├── Translation/   Localizable.strings for en, de, es, fr, ru, tr, zh-Hans
└── Assets.xcassets
docs/assets/       README banner, logo, demo GIF and screenshots
Images/            Logo artwork
```

## Build and release

There is no CI in this repository; builds and archives are produced from Xcode.
Release history lives in [CHANGELOG.md](CHANGELOG.md).

## Screenshots

<p align="center">
<img src="docs/assets/screenshot-01.png" width="300">
<img src="docs/assets/screenshot-02.png" width="300">
</p>

<p align="center">
<img src="docs/assets/screenshot-03.png" width="300">
<img src="docs/assets/screenshot-04.png" width="300">
</p>

<p align="center">
<img src="docs/assets/screenshot-05.png" width="300">
<img src="docs/assets/screenshot-06.png" width="300">
</p>

## Credits

I would like to thank **The Transport for Edinburgh Open Data API** for its contribution to the project.

## License

Released under the [MIT License](LICENSE). Copyright (c) 2022-2026 Can Duru.

## Author

Can Duru — [canduru.net](https://canduru.net) · [github.com/CanDuru4](https://github.com/CanDuru4) · can@canduru.net
