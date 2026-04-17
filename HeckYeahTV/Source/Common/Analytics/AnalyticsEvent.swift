//
//  AnalyticsEvent.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/17/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Strongly-typed analytics events for HeckYeahTV.
/// Add new events here to maintain type safety and documentation.
enum AnalyticsEvent: Sendable {
    
    // MARK: - Channel Events
    
    /// User viewed a channel
    case channelViewed(channelId: String, channelName: String, source: ChannelSource)
    
    /// User favorited a channel
    case channelFavorited(channelId: String, channelName: String)
    
    /// User unfavorited a channel
    case channelUnfavorited(channelId: String, channelName: String)
    
    // MARK: - Tuner Events
    
    /// HDHomeRun tuner discovered
    case tunerDiscovered(deviceId: String, deviceName: String, channelCount: Int)
    
    /// HDHomeRun tuner connection failed
    case tunerConnectionFailed(deviceId: String, error: String)
    
    /// HDHomeRun device enabled/disabled
    case tunerToggled(deviceId: String, isEnabled: Bool)
    
    // MARK: - Import/Refresh Events
    
    /// User manually refreshed IPTV channels
    case iptvRefreshRequested(channelCount: Int, success: Bool)
    
    /// User manually refreshed HDHomeRun tuners
    case homeRunRefreshRequested(deviceCount: Int, success: Bool)
    
    // MARK: - Filter Events
    
    /// User toggled "Show Favorites Only" filter
    case favoritesFilterToggled(isEnabled: Bool)
    
    /// User filtered by country
    case countryFilterApplied(countryCode: String, countryName: String)
    
    /// User filtered by category
    case categoryFilterApplied(categoryId: String, categoryName: String)
    
    // MARK: - Navigation Events
    
    /// User viewed the recents screen
    case recentsScreenViewed(recentCount: Int)
    
    /// User selected a channel from recents
    case recentChannelSelected(channelId: String)
    
    /// User viewed settings screen
    case settingsScreenViewed
    
    /// Screen view for any view
    case screenViewed(screenName: String)
    
    // MARK: - Playback Events
    
    /// Playback started
    case playbackStarted(channelId: String, streamQuality: String)
    
    /// Playback stopped
    case playbackStopped(channelId: String, duration: TimeInterval)
    
    /// Playback error occurred
    case playbackError(channelId: String, error: String)
    
    // MARK: - Subtitle Events
    
    /// User enabled subtitles
    case subtitlesEnabled(channelId: String, trackName: String)
    
    /// User disabled subtitles
    case subtitlesDisabled(channelId: String)
    
    /// User changed subtitle track
    case subtitleTrackChanged(channelId: String, trackName: String)
    
    // MARK: - Audio Track Events
    
    /// User changed audio track
    case audioTrackChanged(channelId: String, trackName: String)
    
    // MARK: - Bundle Events
    
    /// User created a channel bundle
    case bundleCreated(bundleName: String, channelCount: Int)
    
    /// User deleted a channel bundle
    case bundleDeleted(bundleName: String, channelCount: Int)
    
    /// User switched active bundle
    case bundleSwitched(bundleName: String, channelCount: Int)
    
    /// User added a channel to a bundle
    case channelAddedToBundle(channelId: String, channelName: String, bundleName: String)
    
    /// User removed a channel from a bundle
    case channelRemovedFromBundle(channelId: String, channelName: String, bundleName: String)
    
    // MARK: - Event Properties
    
    var name: String {
        switch self {
        // Channel Events
        case .channelViewed: return "channel_viewed"
        case .channelFavorited: return "channel_favorited"
        case .channelUnfavorited: return "channel_unfavorited"
            
        // Tuner Events
        case .tunerDiscovered: return "tuner_discovered"
        case .tunerConnectionFailed: return "tuner_connection_failed"
        case .tunerToggled: return "tuner_toggled"
            
        // Import/Refresh Events
        case .iptvRefreshRequested: return "iptv_refresh_requested"
        case .homeRunRefreshRequested: return "homerun_refresh_requested"
            
        // Filter Events
        case .favoritesFilterToggled: return "favorites_filter_toggled"
        case .countryFilterApplied: return "country_filter_applied"
        case .categoryFilterApplied: return "category_filter_applied"
            
        // Navigation Events
        case .recentsScreenViewed: return "recents_screen_viewed"
        case .recentChannelSelected: return "recent_channel_selected"
        case .settingsScreenViewed: return "settings_screen_viewed"
        case .screenViewed: return "screen_viewed"
            
        // Playback Events
        case .playbackStarted: return "playback_started"
        case .playbackStopped: return "playback_stopped"
        case .playbackError: return "playback_error"
            
        // Subtitle Events
        case .subtitlesEnabled: return "subtitles_enabled"
        case .subtitlesDisabled: return "subtitles_disabled"
        case .subtitleTrackChanged: return "subtitle_track_changed"
            
        // Audio Track Events
        case .audioTrackChanged: return "audio_track_changed"
            
        // Bundle Events
        case .bundleCreated: return "bundle_created"
        case .bundleDeleted: return "bundle_deleted"
        case .bundleSwitched: return "bundle_switched"
        case .channelAddedToBundle: return "channel_added_to_bundle"
        case .channelRemovedFromBundle: return "channel_removed_from_bundle"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        // Channel Events
        case .channelViewed(let id, let name, let source):
            return [
                "channel_id": id,
                "channel_name": name,
                "source": source.rawValue
            ]
            
        case .channelFavorited(let id, let name),
             .channelUnfavorited(let id, let name):
            return [
                "channel_id": id,
                "channel_name": name
            ]
            
        // Tuner Events
        case .tunerDiscovered(let deviceId, let deviceName, let channelCount):
            return [
                "device_id": deviceId,
                "device_name": deviceName,
                "channel_count": channelCount
            ]
            
        case .tunerConnectionFailed(let deviceId, let error):
            return [
                "device_id": deviceId,
                "error": error
            ]
            
        case .tunerToggled(let deviceId, let isEnabled):
            return [
                "device_id": deviceId,
                "is_enabled": isEnabled
            ]
            
        // Import/Refresh Events
        case .iptvRefreshRequested(let channelCount, let success):
            return [
                "channel_count": channelCount,
                "success": success
            ]
            
        case .homeRunRefreshRequested(let deviceCount, let success):
            return [
                "device_count": deviceCount,
                "success": success
            ]
            
        // Filter Events
        case .favoritesFilterToggled(let isEnabled):
            return ["is_enabled": isEnabled]
            
        case .countryFilterApplied(let code, let name):
            return [
                "country_code": code,
                "country_name": name
            ]
            
        case .categoryFilterApplied(let id, let name):
            return [
                "category_id": id,
                "category_name": name
            ]
            
        // Navigation Events
        case .recentsScreenViewed(let recentCount):
            return ["recent_count": recentCount]
            
        case .recentChannelSelected(let channelId):
            return ["channel_id": channelId]
            
        case .settingsScreenViewed:
            return [:]
            
        case .screenViewed(let screenName):
            return ["screen_name": screenName]
            
        // Playback Events
        case .playbackStarted(let channelId, let quality):
            return [
                "channel_id": channelId,
                "stream_quality": quality
            ]
            
        case .playbackStopped(let channelId, let duration):
            return [
                "channel_id": channelId,
                "duration_seconds": Int(duration)
            ]
            
        case .playbackError(let channelId, let error):
            return [
                "channel_id": channelId,
                "error": error
            ]
            
        // Subtitle Events
        case .subtitlesEnabled(let channelId, let trackName),
             .subtitleTrackChanged(let channelId, let trackName):
            return [
                "channel_id": channelId,
                "track_name": trackName
            ]
            
        case .subtitlesDisabled(let channelId):
            return ["channel_id": channelId]
            
        // Audio Track Events
        case .audioTrackChanged(let channelId, let trackName):
            return [
                "channel_id": channelId,
                "track_name": trackName
            ]
            
        // Bundle Events
        case .bundleCreated(let name, let count),
             .bundleSwitched(let name, let count):
            return [
                "bundle_name": name,
                "channel_count": count
            ]
            
        case .bundleDeleted(let name, let count):
            return [
                "bundle_name": name,
                "channel_count": count
            ]
            
        case .channelAddedToBundle(let channelId, let channelName, let bundleName),
             .channelRemovedFromBundle(let channelId, let channelName, let bundleName):
            return [
                "channel_id": channelId,
                "channel_name": channelName,
                "bundle_name": bundleName
            ]
        }
    }
}

// MARK: - Supporting Types

/// Channel source for analytics tracking
enum ChannelSource: String, Sendable {
    case guide = "guide"
    case recents = "recents"
    case favorites = "favorites"
    case search = "search"
    case directInput = "direct_input"
}
