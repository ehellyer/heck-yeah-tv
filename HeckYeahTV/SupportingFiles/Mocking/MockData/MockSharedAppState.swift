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
        self.selectedChannel = nil
        self.scanForTuners = true
        self.selectedChannelBundleId = "mock#1.guide"// AppKeys.Application.defaultChannelBundleId
        self.dateLastHomeRunChannelProgramFetch = nil
        self.dateLastIPTVChannelFetch = nil
        self.closedCaptionsEnabled = false
        self.availableSubtitleTracks = []
        self.selectedSubtitleTrackIndex = nil
        self.availableAudioTracks = []
        self.selectedAudioTrackIndex = nil
        self.playerVolume = 120
        self.isSeekable = true
    }

    var isPlayerPaused: Bool
    var showAppMenu: Bool
    var showProgramDetailCarousel: ChannelProgram?
    var selectedTab: AppSection
    var selectedChannel: ChannelId? {
        didSet {
            if let channelId = selectedChannel {
                // Add to recently viewed in SwiftData
                let swiftDataController = InjectedValues[\.swiftDataController]
                swiftDataController.addRecentlyViewedChannel(channelId: channelId)
            }
        }
    }
    var scanForTuners: Bool?
    var selectedChannelBundleId: ChannelBundleId
    var dateLastHomeRunChannelProgramFetch: Date?
    var dateLastIPTVChannelFetch: Date?
    var closedCaptionsEnabled: Bool
    var availableSubtitleTracks: [SubtitleTrack]
    var selectedSubtitleTrackIndex: Int32?
    var availableAudioTracks: [AudioTrack]
    var selectedAudioTrackIndex: Int32?
    var playerVolume: Int32
    var isSeekable: Bool
}
