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
    
    var selectedTab: TabSection {
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
    
    /// Gets the list of recent channels selected.  This is a LIFO list.  0-n  Where 0 is most recent and n is the oldest used.
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
}
