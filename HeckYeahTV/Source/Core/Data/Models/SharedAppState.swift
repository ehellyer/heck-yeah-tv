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
}

@MainActor
protocol AppStateProvider {
    var isPlayerPaused: Bool { get set }
    var isGuideVisible: Bool { get set }
    var showFavoritesOnly: Bool { get set }
    var selectedTab: TabSection { get set }
    var selectedChannel: ChannelId? { get set }
}

@MainActor @Observable
final class MockSharedAppState: AppStateProvider {
    
    var isPlayerPaused: Bool
    var isGuideVisible: Bool
    var showFavoritesOnly: Bool
    var selectedTab: TabSection
    var selectedChannel: ChannelId?
    
    init(
        isPlayerPaused: Bool = false,
        isGuideVisible: Bool = false,
        showFavoritesOnly: Bool = false,
        selectedTab: TabSection = .channels,
        selectedChannel: ChannelId? = nil) {
            
        self.isPlayerPaused = isPlayerPaused
        self.isGuideVisible = isGuideVisible
        self.showFavoritesOnly = showFavoritesOnly
        self.selectedTab = selectedTab
        self.selectedChannel = selectedChannel
    }
}
