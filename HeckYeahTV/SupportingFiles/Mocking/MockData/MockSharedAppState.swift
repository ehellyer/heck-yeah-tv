//
//  MockSharedAppState.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/7/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Observation

@MainActor @Observable
final class MockSharedAppState: AppStateProvider {
    
    init() {
        self.isPlayerPaused = false
        self.showAppMenu = false
        self.showProgramDetailCarousel = nil
        self.selectedTab = .guide
        self.scanForTuners = true
        self.selectedChannelBundleId = "mock#1.guide"// AppKeys.Application.defaultChannelBundleId
        self.dateLastHomeRunChannelProgramFetch = nil
        self.dateLastIPTVChannelFetch = nil
        self.availableSubtitleTracks = []
        self.selectedSubtitleTrackIndex = -1
        self.availableAudioTracks = []
        self.selectedAudioTrackIndex = -1
        self.playerVolume = 100
        self.preMutedVolume = nil
        self.isReloadingIPTV = false
        self.isReloadingHomeRun = false
    }


    var isPlayerPaused: Bool
    var showAppMenu: Bool
    var showProgramDetailCarousel: ChannelProgram?
    var selectedTab: AppSection
    var scanForTuners: Bool?
    var selectedChannelBundleId: ChannelBundleId
    var dateLastHomeRunChannelProgramFetch: Date?
    var dateLastIPTVChannelFetch: Date?
    var availableSubtitleTracks: [TrackItem]
    var selectedSubtitleTrackIndex: Int
    var availableAudioTracks: [TrackItem]
    var selectedAudioTrackIndex: Int
    var playerVolume: Int32
    var preMutedVolume: Int32?
    var isReloadingIPTV: Bool
    var isReloadingHomeRun: Bool
}
