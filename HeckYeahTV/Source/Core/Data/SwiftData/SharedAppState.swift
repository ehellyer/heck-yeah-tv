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
final class SharedAppState {
    
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
    
    var isGuideVisible: Bool {
        get {
            access(keyPath: \.isGuideVisible)
            return UserDefaults.isGuideVisible
        }
        set {
            withMutation(keyPath: \.isGuideVisible) {
                UserDefaults.isGuideVisible = newValue
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
                UserDefaults.selectedChannel = newValue
            }
        }
    }
    
    // New: pure-Swift HLS proxy settings
    var useHLSProxy: Bool {
        get {
            access(keyPath: \.useHLSProxy)
            return UserDefaults.useHLSProxy
        }
        set {
            withMutation(keyPath: \.useHLSProxy) {
                UserDefaults.useHLSProxy = newValue
            }
        }
    }
    
    var hlsProxyPort: Int {
        get {
            access(keyPath: \.hlsProxyPort)
            return UserDefaults.hlsProxyPort
        }
        set {
            withMutation(keyPath: \.hlsProxyPort) {
                UserDefaults.hlsProxyPort = newValue
            }
        }
    }
}

