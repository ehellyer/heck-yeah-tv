//
//  SharedAppState.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 10/7/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Observation

@MainActor @Observable
final class SharedAppState: AppStateProvider {
    
    static var shared = SharedAppState()
    
    private init() { }
    
    /// Is the player paused? Spoiler alert: if the video isn't moving, it's paused.
    var isPlayerPaused: Bool {
        get {
            access(keyPath: \.isPlayerPaused)
            return UserDefaults.isPlayerPaused
        }
        set {
            withMutation(keyPath: \.isPlayerPaused) {
                UserDefaults.isPlayerPaused = newValue
            }
        }
    }
    
    /// Show the navigation UI or go full stealth mode. Your choice.
    var showAppNavigation: Bool {
        get {
            access(keyPath: \.showAppNavigation)
            return UserDefaults.showAppNavigation
        }
        set {
            withMutation(keyPath: \.showAppNavigation) {
                UserDefaults.showAppNavigation = newValue
            }
        }
    }
    
    /// Only show the good channels. Life's too short for the rest.
    var showFavoritesOnly: Bool {
        get {
            access(keyPath: \.showFavoritesOnly)
            return UserDefaults.showFavoritesOnly
        }
        set {
            withMutation(keyPath: \.showFavoritesOnly) {
                UserDefaults.showFavoritesOnly = newValue
            }
        }
    }
    
    /// Which country? All of them? None of them? The suspense is killing me.
    var selectedCountry: CountryCode? {
        get {
            access(keyPath: \.selectedCountry)
            return UserDefaults.selectedCountry
        }
        set {
            withMutation(keyPath: \.selectedCountry) {
                UserDefaults.selectedCountry = newValue
            }
        }
    }
    
    /// Filter by category? Or embrace the chaos of all channels at once?
    var selectedCategory: CategoryId?
    
    /// Filter by channel title search term. Because scrolling through 10,000 channels wasn't tedious enough.
    var searchTerm: String?
    
    /// Which tab are you pretending to use right now?
    var selectedTab: AppSection {
        get {
            access(keyPath: \.selectedTab)
            return UserDefaults.selectedTab
        }
        set {
            withMutation(keyPath: \.selectedTab) {
                UserDefaults.selectedTab = newValue
            }
        }
    }
    
    /// The channel you're watching. We're totally not keeping track. (We are.)
    var selectedChannel: ChannelId? {
        get {
            access(keyPath: \.selectedChannel)
            return UserDefaults.selectedChannel
        }
        set {
            withMutation(keyPath: \.selectedChannel) {
                if let channelId = newValue {
                    recentChannelIds = addRecentChannelId(channelId)
                }
                UserDefaults.selectedChannel = newValue
            }
        }
    }
    
    /// Your channel-surfing shame, preserved forever in a LIFO stack. 0 = your most recent bad decision.
    private(set) var recentChannelIds: [ChannelId] {
        get {
            access(keyPath: \.recentChannelIds)
            return UserDefaults.recentChannelIds
        }
        set {
            withMutation(keyPath: \.recentChannelIds) {
                UserDefaults.recentChannelIds = newValue
            }
        }
    }
    
    /// Scan for tuners. It's like a treasure hunt, but for TV hardware you forgot you owned.
    var scanForTuners: Bool {
        get {
            access(keyPath: \.scanForTuners)
            return UserDefaults.scanForTuners
        }
        set {
            withMutation(keyPath: \.scanForTuners) {
                UserDefaults.scanForTuners = newValue
            }
        }
    }
}
