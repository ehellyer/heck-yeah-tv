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
        self.recentChannelIds = []
        self.scanForTuners = true
        self.selectedChannelBundleId = "mock#1.guide"// AppKeys.Application.defaultChannelBundleId
        self.dateLastHomeRunChannelProgramFetch = nil
        self.dateLastIPTVChannelFetch = nil
    }
    
    var isPlayerPaused: Bool
    var showAppMenu: Bool
    var showProgramDetailCarousel: ChannelProgram?
    var selectedTab: AppSection
    var selectedChannel: ChannelId? {
        didSet {
            if let channelId = selectedChannel {
                recentChannelIds = addRecentChannelId(channelId)
            }
        }
    }
    var recentChannelIds: [ChannelId]
    var scanForTuners: Bool?
    var selectedChannelBundleId: ChannelBundleId
    var dateLastHomeRunChannelProgramFetch: Date?
    var dateLastIPTVChannelFetch: Date?

    
    func resetRecentChannelIds() {
        recentChannelIds = []
    }
}
