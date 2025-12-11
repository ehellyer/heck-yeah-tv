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
