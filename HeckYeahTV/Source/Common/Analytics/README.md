# Analytics Implementation Guide

## Overview

The HeckYeahTV analytics system is built on Firebase Analytics with a clean, type-safe abstraction layer.

## Architecture

- **AnalyticsService.swift** - Protocol and implementations (Firebase + Mock)
- **AnalyticsEvent.swift** - Strongly-typed event definitions
- **AnalyticsInjectionKey.swift** - Dependency injection setup
- **View+Analytics.swift** - SwiftUI convenience modifiers

## Usage Examples

### 1. Screen Tracking (Automatic)

Use the `.trackScreen()` modifier in your views:

```swift
struct SettingsView: View {
    var body: some View {
        List {
            // ... settings content
        }
        .trackScreen("Settings")
    }
}
```

### 2. Manual Event Logging

Inject the analytics service and log events:

```swift
class PlayerViewModel {
    @Injected(\.analytics) private var analytics
    
    func playChannel(_ channel: Channel) {
        analytics.log(.playbackStarted(
            channelId: channel.id,
            streamQuality: channel.quality
        ))
    }
}
```

### 3. In SwiftData Controllers

```swift
class SwiftDataController {
    @Injected(\.analytics) private var analytics
    
    func toggleFavorite(_ channel: Channel) {
        if channel.isFavorite {
            analytics.log(.channelUnfavorited(
                channelId: channel.id,
                channelName: channel.name
            ))
        } else {
            analytics.log(.channelFavorited(
                channelId: channel.id,
                channelName: channel.name
            ))
        }
    }
}
```

### 4. In Import Services

```swift
class HomeRunImporter {
    @Injected(\.analytics) private var analytics
    
    func load() async throws {
        let result = try await controller.fetchAll()
        
        analytics.log(.homeRunRefreshRequested(
            deviceCount: result.devices.count,
            success: true
        ))
    }
}
```

## Key Performance Indicators (KPIs)

### Channel Usage
- `channelViewed` - Track which channels are most popular
- `channelFavorited` / `channelUnfavorited` - Favorite usage patterns

### Tuner Usage
- `tunerDiscovered` - HDHomeRun device adoption
- `tunerToggled` - Device enable/disable patterns
- `tunerConnectionFailed` - Connection reliability

### User Actions
- `iptvRefreshRequested` - Manual IPTV refresh frequency
- `homeRunRefreshRequested` - Manual tuner refresh frequency
- `favoritesFilterToggled` - "Show Favorites Only" usage
- `recentsScreenViewed` - Recent channels feature usage

### Playback Features
- `subtitlesEnabled` / `subtitlesDisabled` - Subtitle adoption
- `subtitleTrackChanged` - Multi-language subtitle usage
- `audioTrackChanged` - Audio track selection patterns

## User Properties

Set user properties for segmentation:

```swift
analytics.setUserProperty("true", forName: "has_hdhomerun")
analytics.setUserProperty("\(channelCount)", forName: "total_channels")
```

## Enable/Disable Analytics

Analytics can be toggled (for future user preference):

```swift
@Injected(\.analytics) private var analytics

func updateAnalyticsPreference(_ enabled: Bool) {
    analytics.setAnalyticsEnabled(enabled)
}
```

## Testing & Previews

Use `MockAnalyticsService` in previews:

```swift
#Preview {
    InjectedValues[\.analytics] = MockAnalyticsService()
    
    return SettingsView()
}
```

## Debug Logging

In debug builds, analytics events are logged to console when `debugLogging: true`:

```
📊 Analytics: channel_viewed - ["channel_id": "123", "channel_name": "ABC", "source": "guide"]
```

## Privacy Considerations

- **No PII**: Never log personally identifiable information
- **Anonymized IDs**: Use internal IDs, not user names or emails
- **User Control**: Analytics can be disabled via `setAnalyticsEnabled(false)`

## Adding New Events

1. Add a new case to `AnalyticsEvent` enum
2. Implement `name` and `parameters` in the switch statements
3. Log the event where appropriate
4. Test with `MockAnalyticsService`

Example:

```swift
// 1. Add to AnalyticsEvent enum
case bundleEdited(bundleId: String, channelCount: Int)

// 2. Add to name property
case .bundleEdited: return "bundle_edited"

// 3. Add to parameters property
case .bundleEdited(let id, let count):
    return [
        "bundle_id": id,
        "channel_count": count
    ]

// 4. Log it
analytics.log(.bundleEdited(bundleId: bundle.id, channelCount: bundle.channels.count))
```

## Firebase Console

View analytics in Firebase Console:
- Events: Real-time event monitoring
- Custom Dashboards: Create KPI dashboards
- Audiences: Segment users by behavior
- Funnels: Track user journeys

## Platform Support

Analytics work on all three platforms:
- iOS
- tvOS  
- macOS

Platform-specific behavior is handled automatically by Firebase SDK.
