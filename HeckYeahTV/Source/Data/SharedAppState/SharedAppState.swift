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
    
    var scanForTuners: Bool? {
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
    
    var selectedChannelBundleId: ChannelBundleId {
        get {
            access(keyPath: \.selectedChannelBundleId)
            return UserDefaults.selectedChannelBundleId
        }
        set {
            withMutation(keyPath: \.selectedChannelBundleId) {
                UserDefaults.selectedChannelBundleId = newValue
            }
        }
    }
    
    var dateLastHomeRunChannelProgramFetch: Date? {
        get {
            access(keyPath: \.dateLastHomeRunChannelProgramFetch)
            return UserDefaults.dateLastHomeRunChannelProgramFetch
        }
        set {
            withMutation(keyPath: \.dateLastHomeRunChannelProgramFetch) {
                UserDefaults.dateLastHomeRunChannelProgramFetch = newValue
            }
        }
    }
    
    var dateLastIPTVChannelFetch: Date? {
        get {
            access(keyPath: \.dateLastIPTVChannelFetch)
            return UserDefaults.dateLastIPTVChannelFetch
        }
        set {
            withMutation(keyPath: \.dateLastIPTVChannelFetch) {
                UserDefaults.dateLastIPTVChannelFetch = newValue
            }
        }
    }

    var closedCaptionsEnabled: Bool {
        get {
            access(keyPath: \.closedCaptionsEnabled)
            return UserDefaults.closedCaptionsEnabled
        }
        set {
            withMutation(keyPath: \.closedCaptionsEnabled) {
                UserDefaults.closedCaptionsEnabled = newValue
            }
        }
    }
    
    var availableSubtitleTracks: [SubtitleTrack] = []
    var selectedSubtitleTrackIndex: Int32? = nil
    var availableAudioTracks: [AudioTrack] = []
    var selectedAudioTrackIndex: Int32? = nil
    
    var playerVolume: Int32 {
        get {
            access(keyPath: \.playerVolume)
            return UserDefaults.playerVolume
        }
        set {
            withMutation(keyPath: \.playerVolume) {
                UserDefaults.playerVolume = newValue
            }
        }
    }
    
    var isSeekable: Bool = true
    var isReloadingIPTV: Bool = false
    var isReloadingHomeRun: Bool = false
}
