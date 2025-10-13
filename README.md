# Heck Yeah TV

A cross‑platform TV app for iOS, iPadOS, tvOS, and macOS that helps cord‑cutters watch free live TV from public internet streams and over‑the‑air channels via HDHomeRun network tuners.

Project status: Under active development. APIs and structures may change frequently.

---

## Goals
- Deliver a smooth, native Apple‑platform experience for free live TV
- Aggregate IPTV internet streams and HDHomeRun OTA channels into one guide
- Provide fast channel surfing with Favorites, Last Channel, and keyboard/remote shortcuts
- Offer a clean, SwiftUI‑first codebase that’s easy to extend

---

## Current Features

Implemented / In progress
- Bootstrap on launch: discovers HDHomeRun tuners, fetches IPTV streams, imports channels into local persistence, then presents the main UI
- Unified channel import pipeline (IPTV + HDHomeRun) wired into app startup
- SwiftData persistence layer (via a DataPersistence container/context)
- Cross‑platform SwiftUI app entry and root view flow
- VLC playback frameworks integrated via CocoaPods (MobileVLCKit on iOS, TVVLCKit on tvOS)
- Shared JSON utilities via the Hellfire Swift package (JSONSerializable protocol)

Planned / Roadmap
- Unified channel guide UI and browsing
- Favorites and last‑channel persistence across launches
- Search and advanced filters (country, category, language, provider)
- EPG integration (XMLTV/JSON) and timeline guide
- Picture‑in‑Picture (where supported)
- M3U/playlist import and custom sources
- tvOS remote shortcuts; macOS/iPadOS keyboard shortcuts
- Parental controls and channel hiding

---

## Architecture (high level)

Boot flow (implemented)
- Heck_Yeah_TVApp starts a bootstrap Task on launch
- HDHomeRunDiscoveryController bootstraps tuner discovery and channel list
- IPTVController fetches internet stream metadata
- FetchSummary aggregates success/failure details for diagnostics
- ChannelImporter merges/imports both sources into the SwiftData store
- isBootComplete flips to true on the main thread, presenting RootView

Playback (infrastructure present)
- VLC frameworks are integrated through CocoaPods (MobileVLCKit/TVVLCKit)
- A SwiftUI player wrapper may be used to host VLC views per platform (implementation may evolve)

Data & utilities
- Persistence: SwiftData via DataPersistence.shared.container and .viewContext
- JSON model helpers: Hellfire package with JSONSerializable protocol for ergonomic encode/decode

Referenced types (present in the app but not shown here)
- RootView
- HDHomeRunDiscoveryController
- IPTVController
- FetchSummary
- DataPersistence
- ChannelImporter

---

## Tech Stack
- Language: Swift
- UI: SwiftUI
- Persistence: SwiftData
- Playback: libVLC via MobileVLCKit (iOS/macOS) and TVVLCKit (tvOS)
- Concurrency: Swift structured concurrency (async/await, Task)
- Utilities: Hellfire package (JSONSerializable)

Note: libVLC is resilient to diverse HLS/TS streams commonly used by IPTV sources. The player abstraction can evolve to support alternate backends if desired.

---

## Platform & Requirements
- Xcode: latest recommended
- Platforms (minimums aligned to Package.swift and targets):
  - iOS 18+
  - tvOS 18+
  - macOS 15+
- CocoaPods for VLC frameworks (MobileVLCKit, TVVLCKit)

---

## Building the Project

1) Clone the repository and open the Xcode workspace if using CocoaPods (recommended when VLC is enabled).
- If the repo includes a Podfile, run:
  - gem install cocoapods (if needed)
  - pod install
  - Open the generated .xcworkspace

2) Select a platform target (iOS, iPadOS, tvOS, or macOS) and set a signing team.

3) Build & Run.

Notes
- VLC frameworks: MobileVLCKit (iOS/macOS) and TVVLCKit (tvOS) are integrated via CocoaPods, with acknowledgements included in the repo.
- If you prefer to defer VLC, you can stub the player backend and integrate later.

---

## Data Sources

- Public Internet Streams: The app fetches IPTV stream metadata via IPTVController (compatible with iptv‑org style sources).
- HDHomeRun (Silicondust): Discovers tuners on the local network and ingests OTA channel lineups.

Legal & Availability Notice
This app aggregates publicly accessible streams. Availability, stability, and rights to view content vary by provider and region. Users are responsible for complying with local laws and terms of service for each stream. The project does not host or redistribute streams.

---

## Development Notes

- App entry: Heck_Yeah_TVApp starts the bootstrap sequence and toggles isBootComplete to present RootView when imports finish.
- Persistence: DataPersistence exposes a SwiftData container and view context. ChannelImporter writes imported channels to the store.
- JSON: Models can adopt JSONSerializable from the Hellfire package for consistent encoding/decoding and diagnostics.

---

## Contributing

- Keep Swift models simple and consistent (Codable/Sendable where applicable). JSONSerializable is available for convenience.
- Prefer SwiftUI for UI layers; keep UIKit/AppKit shims minimal and isolated.
- Use structured concurrency (async/await) for async work.
- Add doc comments with usage examples for new types.
- Include unit tests for domain logic (adapters, importers, state transitions).
- Use small, focused PRs with clear commit messages.

---

## Roadmap (short list)

- HDHomeRun discovery resilience (retry, Wi‑Fi changes)
- VLC backend events surfaced to SwiftUI (buffering, errors, stats)
- Favorites & last‑channel persistence across launches
- Search + filters UI
- EPG integration and timeline guide
- M3U import & custom sources
- tvOS remote shortcuts; macOS/iPadOS keyboard shortcuts
- PiP support

---

## Privacy

This app does not collect personal information. Network requests are made directly to stream providers or to devices on your LAN (e.g., HDHomeRun). See third‑party providers for their own policies.

---

## License

TBD

---

## Acknowledgements

- The iptv‑org community for openly cataloging free IPTV streams
- Silicondust HDHomeRun for making OTA access via network tuners possible
- VideoLAN / libVLC for a robust cross‑platform media engine
- Hellfire JSON utilities used in this project
