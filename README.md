# Heck Yeah TV

A cross‑platform TV app for **iOS, iPadOS, tvOS, and macOS** that helps cord‑cutters watch **free live TV** from public internet streams and **over‑the‑air** channels via HDHomeRun network tuners.

> **Project status:** Under active development. APIs and structures may change frequently.

---

## Goals
- Deliver a smooth, native Apple‑platform experience for free live TV
- Aggregate **IPTV internet streams** (e.g., iptv‑org) and **HDHomeRun OTA** channels into one guide
- Provide fast channel surfing with **Favorites**, **Last Channel**, and **keyboard/remote shortcuts**
- Offer a clean, SwiftUI‑first codebase that’s easy to extend

---

## Features
### Implemented / In progress
- **Unified channel guide** sourced from free IP streams and (optionally) HDHomeRun devices on the LAN
- **Favorites**: star/unstar channels; quick filter view
- **Last channel**: jump back to the previously playing channel
- **Background handling**: gracefully pauses playback and persists session state
- **Cross‑platform UI** using SwiftUI; adaptive layouts for phone, tablet, TV, and desktop

### Planned / Roadmap
- **Search & filters**: by country, category, language, feed, guide provider
- **Program guide (EPG)**: XMLTV/JSON EPG adapters
- **Picture‑in‑Picture** (where supported)
- **Remote control shortcuts** on tvOS; **keyboard shortcuts** on macOS/iPadOS
- **M3U/playlist import**
- **Parental controls** and channel hiding

---

## Data Sources
- **Public Internet Streams**: Project can ingest data modeled after `iptv-org` (e.g., `streams.json`).
- **HDHomeRun** (Silicondust): Discovers tuners on the local network to list and play OTA channels.

> ⚠️ **Legal & Availability Notice**
> This app aggregates **publicly accessible** streams. Availability, stability, and rights to view content vary by provider and region. Users are responsible for complying with local laws and terms of service for each stream. The project does not host or redistribute streams.

---

## Architecture Overview

```
[Internet Streams]   [HDHomeRun OTA]
        |                   |
        v                   v
     StreamAdapter      HDHRAdapter
            \           /
             v         v
          Unified Channel Domain  <— favorites, last channel, filters
                     |
                 GuideStore  (ObservableObject)
                     |
      ┌──────────────┼───────────────────┐
      v              v                   v
   GuideView     PlayerView          SettingsView
```

**Key concepts**
- **Adapters** normalize heterogeneous inputs (internet/IPTV vs. HDHomeRun) into a single channel model.
- **GuideStore** is the app’s primary state container (favorites, last channel, selection, persistence, background events).
- **BootGate** is a small startup gate that runs discovery and configuration before showing the main UI.

---

## Tech Stack
- **Language**: Swift
- **UI**: SwiftUI
- **Playback**: `libVLC` via **MobileVLCKit/TVVLCKit** (recommended) or any AVFoundation‑compatible player (pluggable)
- **Concurrency**: Swift structured concurrency (`async/await`, `Task`)

> **Note on playback**: libVLC is resilient to diverse HLS/TS streams commonly used by IPTV sources. Player is abstracted so a different backend can be swapped in if desired.

---

## Project Structure (proposed)
```
HeckYeahTV/
├─ App/
│  ├─ Heck_Yeah_TVApp.swift
│  ├─ BootGate.swift
│  └─ AppTheme.swift
├─ Features/
│  ├─ Guide/
│  │  ├─ GuideView.swift
│  │  ├─ ChannelRow.swift
│  │  └─ Filters/
│  ├─ Player/
│  │  ├─ PlayerView.swift
│  │  └─ TVVLCViewRepresentable.swift
│  └─ Settings/
├─ Domain/
│  ├─ Models/ (UnifiedChannel, ChannelSource, ...) 
│  └─ Stores/ (GuideStore, PlaybackStore)
├─ Data/
│  ├─ Adapters/ (StreamAdapter, HDHRAdapter, EPGAdapter)
│  └─ Services/ (Discovery, Networking, Persistence)
└─ Resources/
```

---

## Unified Channel Model (example)
This model is used throughout the UI and stores/states. It’s constructed by adapters for each source.

```swift
import Foundation
import Hellfire

struct UnifiedChannel: JSONSerializable {
    let id: String             // unique key (e.g., channelId+feedId or hdhrGuideNumber)
    let title: String          // display name
    let callSign: String?      // e.g., “NBC”, “FOX”
    let logoURL: URL?          // channel logo if available
    let countryCode: String?   // ISO 3166-1 alpha-2
    let category: String?      // e.g., “News”, “Sports”
    let streamURL: URL?        // playable URL if immediate
    let source: Source         // .internet or .hdhomerun

    enum Source: String, Codable, Sendable, Equatable, Hashable { case internet, hdhomerun }

    enum CodingKeys: String, CodingKey {
        case id, title, callSign, logoURL = "logo_url", countryCode = "country_code", category, streamURL = "stream_url", source
    }
}
```

> **Style note**: Model stubs follow the local convention: a `struct` conforming to `JSONSerializable` (Codable, Sendable, Equatable, Hashable), no `public` modifiers or custom initializers, and `CodingKeys` mapping from snake_case JSON.

---

## Boot & Background Handling
**BootGate** performs initial discovery (IPTV fetch, HDHomeRun scan, config) before presenting `RootView`.

```swift
import SwiftUI

@main
struct Heck_Yeah_TVApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var guideStore = GuideStore()
    @State private var isReady = false

    var body: some Scene {
        WindowGroup {
            BootGate(isReady: $isReady) {
                RootView().environmentObject(guideStore)
            }
            .task {
                // Perform discovery/config load here
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                isReady = true
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background { guideStore.appDidEnterBackground() }
        }
    }
}
```

**GuideStore** coordinates playback/session persistence.

```swift
final class GuideStore: ObservableObject {
    @Published var favorites: Set<String> = []
    @Published var lastChannelId: String?

    func toggleFavorite(_ channelId: String) {
        if favorites.contains(channelId) { favorites.remove(channelId) } else { favorites.insert(channelId) }
    }

    func appDidEnterBackground() {
        stopPlayback()
        persistSession()
    }

    private func stopPlayback() {
        NotificationCenter.default.post(name: .stopPlaybackRequested, object: nil)
    }

    private func persistSession() {
        // Save favorites, lastChannelId, filters, etc.
    }
}

extension Notification.Name { static let stopPlaybackRequested = Notification.Name("stopPlaybackRequested") }
```

---

## Playback (VLC) — SwiftUI Wrapper Sketch
Below is a minimal pattern for embedding a VLC player in SwiftUI via a `UIViewRepresentable`/`NSViewRepresentable`.

```swift
import SwiftUI
#if os(tvOS)
import TVVLCKit
#else
import MobileVLCKit
#endif

struct TVVLCView: UIViewRepresentable { // use NSViewRepresentable on macOS
    let url: URL

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let mediaPlayer = VLCMediaPlayer()
        mediaPlayer.drawable = view
        mediaPlayer.media = VLCMedia(url: url)
        context.coordinator.player = mediaPlayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // start/stop/update media here as needed
        context.coordinator.player?.play()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var player: VLCMediaPlayer?
        deinit { player?.stop() }
    }
}
```

> The actual implementation includes platform‑specific nuances, lifecycle hooks, buffering/error events, and responds to `.stopPlaybackRequested`.

---

## Filters & Search (design)
Adapters attach metadata to each `UnifiedChannel` (country, category, language, feed, provider). The guide exposes composable predicates:

```swift
struct ChannelQuery {
    var countries: Set<String> = []
    var categories: Set<String> = []
    var text: String = ""

    func matches(_ c: UnifiedChannel) -> Bool {
        let countryOK = countries.isEmpty || countries.contains(c.countryCode ?? "")
        let categoryOK = categories.isEmpty || categories.contains(c.category ?? "")
        let textOK = text.isEmpty || c.title.localizedCaseInsensitiveContains(text)
        return countryOK && categoryOK && textOK
    }
}
```

---

## Building the Project
### Requirements
- Latest Xcode with Swift & SwiftUI
- Platform SDKs for iOS, iPadOS, tvOS, and macOS

### Steps
1. Clone the repository and open the Xcode project/workspace.
2. Select a platform target (iOS, iPadOS, tvOS, or macOS) and set a signing team for run/debug.
3. (Optional) **libVLC**: Add **MobileVLCKit** (iOS/macOS) and/or **TVVLCKit** (tvOS) via Swift Package Manager or binary frameworks.
4. Build & Run.

> If you prefer AVFoundation first, you can stub the player backend and add VLC later.

---

## Configuration
- **Internet Streams**: You can point an adapter at an `iptv-org` style JSON or your own playlist source.
- **HDHomeRun**: Discovery uses SSDP/HTTP to find tuners and load channel lineup from the local network.
- **EPG**: Planned XMLTV/JSON EPG adapters; mapping by call sign/channel id where possible.

---

## Contributing
- Keep Swift models simple and consistent with the project’s `JSONSerializable` convention.
- Prefer **SwiftUI** for UI layers; keep UIKit/AppKit shims minimal and isolated.
- Add doc comments with usage examples when introducing new types.
- Include unit tests for domain logic (filters, adapters, state transitions).
- Use small, focused PRs with clear commit messages.

---

## Roadmap (short list)
- [ ] HDHomeRun discovery + resilient retry/wifi changes
- [ ] VLC backend events (buffering, errors, stats) surfaced to SwiftUI
- [ ] Favorites & last‑channel persistence across launches
- [ ] Search + advanced filters UI
- [ ] EPG integration and timeline guide
- [ ] M3U import & custom sources
- [ ] tvOS remote shortcuts; macOS/iPad keyboard shortcuts
- [ ] PiP support

---

## Privacy
This app does **not** collect personal information. Network requests are made directly to stream providers or to devices on your LAN (e.g., HDHomeRun). See third‑party providers for their own policies.

---

## License
TBD

---

## Acknowledgements
- The **iptv‑org** community for openly cataloging free IPTV streams
- **Silicondust HDHomeRun** for making OTA access via network tuners possible
- **VideoLAN / libVLC** for a robust cross‑platform media engine
