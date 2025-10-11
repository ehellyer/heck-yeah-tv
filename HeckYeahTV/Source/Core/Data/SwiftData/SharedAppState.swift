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
    
    init() { }
    
    
#if os(tvOS)
    private var _legacyKitFocus: FocusTarget?
    var legacyKitFocus: FocusTarget? {
        get {
            access(keyPath: \.isPlayerPaused)
            return _legacyKitFocus
        }
        set {
            withMutation(keyPath: \.isPlayerPaused) {
                _legacyKitFocus = newValue
            }
        }
    }
#endif
    
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
            return UserDefaults.showFavorites
        }
        set {
            withMutation(keyPath: \.showFavoritesOnly) {
                UserDefaults.showFavorites = newValue
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
}
