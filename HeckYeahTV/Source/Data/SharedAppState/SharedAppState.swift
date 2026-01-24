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
    
    var showAppMenu: Bool {
        get {
            access(keyPath: \.showAppMenu)
            return UserDefaults.showAppMenu
        }
        set {
            withMutation(keyPath: \.showAppMenu) {
                UserDefaults.showAppMenu = newValue
            }
        }
    }
    
    var showProgramDetailCarousel: ChannelProgram? = nil
    
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
    
    var selectedChannelBundle: ChannelBundleId {
        get {
            access(keyPath: \.selectedChannelBundle)
            return UserDefaults.selectedChannelBundle
        }
        set {
            withMutation(keyPath: \.selectedChannelBundle) {
                UserDefaults.selectedChannelBundle = newValue
            }
        }
    }
    
    var dateLastGuideFetch: Date? {
        get {
            access(keyPath: \.dateLastGuideFetch)
            return UserDefaults.dateLastGuideFetch
        }
        set {
            withMutation(keyPath: \.dateLastGuideFetch) {
                UserDefaults.dateLastGuideFetch = newValue
            }
        }
    }
}
