# Heck Yeah TV

A cross-platform TV app for iOS, iPadOS, tvOS, and macOS that helps cord-cutters watch free live TV from public internet streams and over-the-air channels via HDHomeRun network tuners.

Project status: Under active development. Core features implemented, additional features in progress.

---

## Goals
- Deliver a smooth, native Apple-platform experience for free live TV
- Aggregate IPTV internet streams and HDHomeRun OTA channels into one guide
- Provide fast channel surfing with Favorites and Recents
- Offer a clean, SwiftUI-first codebase that's easy to extend
- Support multiple channel bundles for different viewing preferences

---

## Current Features

### Implemented ✅

**Channel Management**
- Channel bundles system for organizing channels into custom groups
- IPTV channel catalog with 8,000+ free internet streams
- HDHomeRun network tuner discovery and integration
- Over-the-air (OTA) channel lineup from discovered tuners
- Manual refresh for IPTV channels and HDHomeRun devices
- Add/remove individual channels to/from bundles
- Enable/disable tuners for inclusion in bundles
- Empty state views with contextual messaging
- Automatic cleanup of orphaned channels when devices are removed

**Filtering & Organization**
- Country-based filtering with flag icons
- Category-based filtering (news, sports, entertainment, etc.)
- Search term filtering for channel names
- Show favorites only toggle
- Recently viewed channels screen (top 10)
- Channel bundle switching with active bundle indicator

**Playback**
- VLC-based video player for robust HLS/TS stream support
- Audio track selection
- Closed caption/subtitle support with track selection
- Volume controls with mute functionality (iOS/macOS/tvOS)
- Stream quality indicators
- Playback watchdog for detecting unplayable streams
- Graceful error handling with retry capability

**User Interface**
- SwiftUI-first design across all platforms
- Guide view with lazy loading for performance
- Channel selection with visual feedback
- Player overlay with transport controls (tvOS)
- Settings screens for managing bundles, devices, and filters
- Dark mode support
- Dynamic Type support
- Glass effect styling for modern UI

**Data & Persistence**
- SwiftData for local persistence
- Channel catalog with program guide integration
- EPG (Electronic Program Guide) data from HDHomeRun and XMLTV sources
- Recently viewed channel history (5000 entry limit)
- Selected channel persistence across launches
- Automatic migration system for schema updates

**Analytics & Monitoring**
- Firebase Analytics integration (toggleable)
- Comprehensive event tracking:
  - Screen views (Guide, Settings, Recents, Player)
  - Channel viewing with source tracking
  - Bundle operations (create, delete, switch)
  - Filter usage (favorites, country, category)
  - IPTV/HomeRun refresh events
  - Subtitle and audio track changes
  - Channel add/remove from bundles
- Mock analytics implementation for testing
- Type-safe event system

**Architecture & Code Quality**
- Dependency injection system for testability
- Protocol-oriented design
- Swift 6 concurrency support (async/await, actors, Sendable)
- Structured logging system
- Error handling with typed errors
- Comprehensive documentation comments

### In Progress 🚧

**Planned Features**
- Picture-in-Picture support
- AirPlay support
- Mini player mode
- Network change detection
- Bundle copying
- Select all/unselect all in channel picker
- DVR functionality with AI commercial removal
- Behavior settings (channel selection, watchdog timing)
- Mini guide overlay
- Enhanced diagnostics and logging
- Default IPTV channel bundle for fresh installs

---

## Architecture

### Boot Flow
```
App Launch
    ↓
Check for channels in database
    ↓
If empty → Bootstrap (Gated UI)
    • Discover HDHomeRun tuners
    • Fetch IPTV stream metadata
    • Import channels to SwiftData
    • Create default channel bundle
    ↓
If channels exist → Background refresh
    • Update channel catalogs
    • Refresh EPG data
    • Sync device status
    ↓
Present main UI
```

### Core Components

**Import Pipeline**
- Fetches and imports IPTV channels from iptv-org sources
- Discovers HDHomeRun devices and imports their channel lineups
- Manages Electronic Program Guide data from multiple sources
- Concurrent import with progress tracking
- Incremental updates to avoid full catalog reloads

**Data Layer**
- Central data access and manipulation layer
- Efficient channel organization for UI performance
- SwiftData models with migration support
- Type-safe query system
- Reusable channel filtering logic

**Playback**
- Cross-platform VLC integration
- Stream health monitoring
- Playback state management
- Audio/subtitle track management
- Volume and mute control

**Analytics**
- Protocol-based analytics abstraction
- Production analytics with Firebase
- Testing implementation with thread-safe event storage
- Strongly-typed event system
- Automatic screen tracking

---

## Tech Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData with custom migration
- **Playback**: libVLC via MobileVLCKit (iOS/macOS) and TVVLCKit (tvOS)
- **Concurrency**: Swift structured concurrency (async/await, Task, actors)
- **Networking**: Hellfire package
- **Analytics**: Firebase Analytics (optional)
- **Utilities**: Hellfire package (JSONSerializable)
- **Dependency Management**: Swift Package Manager and CocoaPods for VLC frameworks

Note: libVLC provides excellent compatibility with diverse HLS/TS streams commonly used by IPTV sources.

---

## Platform Requirements

- **Xcode**: 16.0 or later
- **Platform Minimums**:
  - iOS 18+
  - tvOS 18+
  - macOS 15+
- **Dependencies**:
  - CocoaPods for VLC frameworks
  - Firebase Analytics SDK (optional)

---

## Building the Project

1. **Install Dependencies**
   ```bash
   gem install cocoapods  # if needed
   pod install
   ```

2. **Open Workspace**
   ```bash
   open HeckYeahTV.xcworkspace
   ```

3. **Configure Signing**
   - Select a platform target (iOS, tvOS, or macOS)
   - Set your development team in signing settings

4. **Build & Run**
   - Select target device/simulator
   - Build and run (⌘R)

### Optional: Firebase Analytics Setup

To enable analytics:
1. Add `GoogleService-Info.plist` to the project
2. Initialize Firebase in `Heck_Yeah_TVApp.swift`
3. Analytics will automatically start tracking events

To disable analytics:
- The app uses `MockAnalyticsService` by default in debug mode
- No Firebase setup required for development

---

## Data Sources

**IPTV Streams**
- Source: iptv-org community catalog
- ~8,000+ free internet streams worldwide
- Metadata includes country, category, language, quality indicators
- Automatic filtering of DRM-protected and invalid streams

**HDHomeRun (Silicondust)**
- Discovers tuners on local network via UDP broadcast
- Fetches channel lineups from each device
- Integrates EPG data when available
- Supports multiple tuners simultaneously

**EPG Data**
- XMLTV format from HDHomeRun tuners
- JSON format from iptv-org sources
- Program information with title, description, time, etc.
- Automatic cleanup of past programs

### Legal & Availability Notice
This app aggregates publicly accessible streams. Availability, stability, and rights to view content vary by provider and region. Users are responsible for complying with local laws and terms of service for each stream. The project does not host or redistribute streams.

---

## Project Structure

```
HeckYeahTV/
├── Source/
│   ├── App/
│   │   ├── Heck_Yeah_TVApp.swift          # App entry point
│   │   └── LegacyAppDelegate.swift         # AppKit/UIKit delegate
│   ├── Common/
│   │   ├── Analytics/                      # Analytics system
│   │   ├── DependencyInjection/           # DI framework
│   │   ├── Extensions/                     # Swift extensions
│   │   ├── Logging/                        # Debug logging
│   │   └── Utilities/                      # App-wide utilities
│   ├── Data/
│   │   ├── Adapters/                       # Data transformation
│   │   ├── DataTransferModels/            # API models
│   │   ├── ImportServices/                # Channel import pipeline
│   │   ├── SharedAppState/                # Observable app state
│   │   └── SwiftData/                     # Persistence layer
│   └── UserInterface/
│       ├── MediaPlayerView/               # VLC player
│       ├── Menu/
│       │   └── Screens/
│       │       ├── Guide/                 # Channel guide
│       │       ├── Recents/               # Recently viewed
│       │       ├── Settings/              # App settings
│       │       └── PlayerOverlay/         # Playback controls
│       └── Root/                          # Root navigation
└── SupportingFiles/
    ├── Assets/                            # Images, colors
    └── Mocking/                           # Test data & mocks
```

---

## Feature Status

### Completed ✅
- Guide View with no channels view and contextual messaging
- Settings View with reload IPTV channels functionality
- Enable/disable channel sources in guide
- Scan for tuners with auto-discovery option
- Include individual device channel lineups in bundles
- Remove offline tuners and cleanup orphaned channels
- Crashlytics and log file support infrastructure
- Comprehensive analytics implementation with Firebase integration

### Planned 📋
- Show clock on guide screen for program schedule matching
- Enhanced player controls for tvOS
- Show selected bundle name on guide
- Picture-in-Picture support
- AirPlay integration
- Mini player mode
- Link to Settings for LAN discovery permissions
- Network change detection and cache invalidation
- Direct channel removal from bundle without filters
- Auto-add new devices to all bundles
- Bundle copy functionality
- Default channel bundle for new installs
- Select all/unselect all in channel picker
- DVR with AI commercial removal
- Behavior settings (dismissal, watchdog timing, player config)
- Mini guide overlay with swipe/arrow navigation
- Enhanced settings with diagnostics and logging
- Default IPTV channel set for fresh installs

---

## Contributing

**Code Style**
- Use PascalCase for types, camelCase for properties/methods
- Prefer `let` over `var` when possible
- Use `@MainActor` for UI-related code
- Follow Swift 6 concurrency best practices (Sendable, actors)
- Add documentation comments for public APIs

**Architecture Guidelines**
- Keep views simple and focused
- Extract business logic into separate types
- Use dependency injection for testability
- Prefer protocols over concrete types for flexibility
- Follow SOLID principles

**SwiftUI Best Practices**
- Use `@State` for view-local state
- Use `@Bindable` for SwiftData models
- Use `@Injected` for dependencies
- Keep `body` implementations readable
- Extract complex views into separate components

**Testing**
- Write unit tests for business logic
- Use `MockAnalyticsService` for analytics testing
- Test error conditions and edge cases
- Use preview providers for UI development

**Pull Requests**
- Keep PRs focused on a single feature or fix
- Include clear descriptions and screenshots for UI changes
- Update documentation for new features
- Ensure builds succeed on all platforms
- Add analytics events for user-facing features

---

## Analytics Events

The app tracks the following user interactions:

**Navigation**
- Screen views (Guide, Settings, Recents, Player)

**Channel Operations**
- Channel viewed (with source: guide/recents/favorites)
- Channel favorited/unfavorited

**Bundle Management**
- Bundle created/deleted/switched
- Channel added to/removed from bundle

**Filtering**
- Favorites filter toggled
- Country filter applied
- Category filter applied

**Playback**
- Subtitles enabled/disabled/changed
- Audio track changed

**Device Management**
- IPTV refresh (with success/failure)
- HomeRun refresh (with device count and success/failure)

All events are strongly-typed and can be disabled via analytics configuration.

---

## Known Issues

- VLC occasionally reports no subtitle tracks on some streams
- HDHomeRun discovery requires LAN access permission on first launch
- Some IPTV streams may have intermittent availability
- Network changes may require manual channel refresh

---

## Performance Optimizations

- Lazy loading in channel guide (only renders visible channels)
- Channel bundle map caching for fast UI updates
- Debounced filter updates to reduce queries
- Efficient SwiftData predicates with indexed properties
- Background import tasks to avoid blocking UI
- Watchdog-based stream monitoring to detect playback issues

---

## Privacy

This app does not collect personal information. Network requests are made directly to:
- Stream providers for IPTV content
- HDHomeRun devices on your local network
- iptv-org for channel metadata
- Firebase Analytics (if enabled) for anonymous usage metrics

The app requires Local Network access permission to discover HDHomeRun tuners.

See third-party providers for their own privacy policies.

---

## License

TBD

---

## Acknowledgements

- The iptv-org community for openly cataloging free IPTV streams
- Silicondust HDHomeRun for making OTA access via network tuners possible
- VideoLAN / libVLC for a robust cross-platform media engine
- Firebase for analytics infrastructure
- Apple for SwiftUI, SwiftData, and excellent developer tools
- The Swift community for language evolution and best practices

---

## Support

For issues, questions, or feature requests, please file an issue on the project repository.

---

**Last Updated**: April 2026
