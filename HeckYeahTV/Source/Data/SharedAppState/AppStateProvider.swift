//
//  AppStateProvider.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/17/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Represents an audio track or subtitle track with its index and display name
struct TrackItem: Identifiable, Hashable, Sendable {
    let id: Int32
    let index: Int32
    let name: String
    
    /// Extract language code from name if present (e.g., "English [en]" -> "en")
    var languageCode: String? {
        // Try to extract language code from patterns like "English [en]" or just "en"
        if let match = name.range(of: #"\[([a-z]{2,3})\]"#, options: .regularExpression) {
            let code = name[match].replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
            return code
        }
        // Check if the name itself is just a language code
        if name.count == 2 || name.count == 3, name.allSatisfy({ $0.isLetter }) {
            return name.lowercased()
        }
        return nil
    }
}

/// Represents the instance state of Heck Yeah TV app.  These are settings that would never be shared across
/// CloudKit (tm) so that all your Heck Yeah TV apps would pause at the same time, or have the same selected channel,
/// or show the same recent channels, etc...

@MainActor
protocol AppStateProvider {
    
    /// Whether the player is currently taking a breather.
    ///
    /// When `true`, your video is frozen in time like a dramatic pause in a soap opera.
    /// When `false`, the show goes on. It's basically the "hold my beer" of video playback states.
    var isPlayerPaused: Bool { get set }
    
    /// Controls whether the app menu is visible or hiding in shame.
    ///
    /// Set to `true` when you want users to actually find things in your app.
    /// Set to `false` when you want a clean, minimalist look (or when you're pretending to be Netflix).
    var showAppMenu: Bool { get set }
    
    /// The program details carousel that demands your full attention.
    ///
    /// When set, this triggers a fancy swipeable carousel to show off program details like it's
    /// auditioning for a design award. Set to `nil` to dismiss it back into the void.
    var showProgramDetailCarousel: ChannelProgram? { get set }

    /// Whether the app should actively hunt for HDHomeRun tuners on your network — if we've even
    /// had the nerve to ask yet.
    ///
    /// - `nil` means the question was never posed. The user is blissfully unaware that tuner
    ///   scanning is even a thing. Show them the prompt before assuming anything.
    /// - `true` unleashes a digital bloodhound to sniff out every tuner device hiding on your LAN.
    /// - `false` means the user said no thanks, and your app minds its own business like a polite
    ///   houseguest who doesn't poke around in your network closet.
    var scanForTuners: Bool? { get set }

    /// The currently selected tab in your app's navigation.
    ///
    /// Because even apps need to organize their lives into sections.
    /// It's like a filing cabinet, but with more SwiftUI and fewer paper cuts.
    var selectedTab: AppSection { get set }
    
    /// The currently selected custom channel bundle from your curated collection.
    ///
    /// Each bundle is a lovingly hand-picked selection from the vast ocean of 24/7 streams,
    /// some educational, some entertaining, most just hypnotic background noise that you'll
    /// swear you're "actively watching" while scrolling on your phone.
    ///
    /// Change this value to switch between different flavors of perpetual content.
    /// "Just one episode", famous last words.
    var selectedChannelBundleId: ChannelBundleId { get set }
    
    /// The last known expedition to the land of guide data.
    ///
    /// This date marks the heroic moment when the app last fetched the HomeRun channel program guide.
    /// Fetching too often may result in angry server admins, sternly-worded emails, or mysterious API outages.
    /// If this value is `nil`, then either we've never checked, or we’re relying on our psychic abilities to guess what’s on.
    /// Use responsibly—your API rate limit (and your reputation) depend on it.
    var dateLastHomeRunChannelProgramFetch: Date? { get set }
    
    /// The last rendezvous with the mysterious world of IPTV channels.
    ///
    /// Remembers the most recent adventure when your app fetched the IPTV channel list.
    /// Checking too frequently may provoke the wrath of server guardians, or at least a stern warning in all caps.
    /// If `nil`, we either haven't fetched yet, or we're just winging it and hoping for the best.
    /// Set this after each successful fetch—your future self (and the API's rate limiter) will thank you.
    var dateLastIPTVChannelFetch: Date? { get set }
    
    /// The list of subtitle tracks available in the currently playing stream.
    ///
    /// This is populated dynamically when a stream starts playing and represents the available
    /// subtitle/caption options (different languages). Empty array means no subtitle tracks
    /// are available or no stream is playing. This state is transient and not persisted.
    var availableSubtitleTracks: [TrackItem] { get set }
    
    /// The index of the currently selected subtitle track, or -1 if CC is disabled.
    ///
    /// This value corresponds to the VLC subtitle track index. When set, it triggers the player
    /// to switch to that subtitle track. Set to -1 when CC is disabled.
    /// This state is transient and not persisted since each stream has unique tracks.
    var selectedSubtitleTrackIndex: Int32 { get set }
    
    /// The list of audio tracks available in the currently playing stream.
    ///
    /// This is populated dynamically when a stream starts playing and represents the available
    /// audio options (different languages, commentary tracks, etc.). Empty array means no audio
    /// tracks are available or no stream is playing. This state is transient and not persisted.
    var availableAudioTracks: [TrackItem] { get set }
    
    /// The index of the currently selected audio track, or -1 if none selected.
    ///
    /// This value corresponds to the VLC audio track index. When set, it triggers the player
    /// to switch to that audio track. Set to -1 when no stream is playing or no track is selected.
    /// This state is transient and not persisted since each stream has unique tracks.
    var selectedAudioTrackIndex: Int32 { get set }
    
    /// The current playback volume level (0-200).
    ///
    /// VLC supports volume levels from 0 (muted) to 200 (double volume), with 100 being normal volume.
    /// Most users stick with 0-100, but VLC lets you crank it to 200 if you're feeling bold or your
    /// audio is recorded at whisper levels. This setting persists across app launches because nobody
    /// wants to manually adjust volume every time they watch something.
    var playerVolume: Int32 { get set }
    
    /// The volume level before the user hit the mute button.
    ///
    /// When you tap mute, your volume gets stored here like a security deposit, ready to be returned
    /// when you unmute. If `nil`, either you've never muted, or the universe has forgotten your
    /// pre-muted volume preference (probably a fresh install). This setting persists because nobody
    /// wants to guess what volume they had before muting across app restarts.
    var preMutedVolume: Int32? { get set }
    
    /// Whether IPTV channels are currently being reloaded.
    ///
    /// When `true`, the app is fetching fresh IPTV channel data from the remote source.
    /// This state is managed by IPTVImporter and observed by UI to show loading indicators.
    var isReloadingIPTV: Bool { get set }
    
    /// Whether HDHomeRun devices are currently being refreshed.
    ///
    /// When `true`, the app is probing the network for tuner devices and fetching their channel lineups.
    /// This state is managed by HomeRunImporter and observed by UI to show loading indicators.
    var isReloadingHomeRun: Bool { get set }
}
