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
    
    var isPlayerPaused: Bool
    var showAppNavigation: Bool
    var selectedTab: AppSection
    var selectedChannel: ChannelId? {
        didSet {
            if let channelId = selectedChannel {
                recentChannelIds = addRecentChannelId(channelId)
            }
        }
    }
    var recentChannelIds: [ChannelId]
    var scanForTuners: Bool

    init(isPlayerPaused: Bool = false,
         showAppNavigation: Bool = false,
         selectedTab: AppSection = .guide,
         selectedChannel: ChannelId? = nil,
         recentChannelIds: [ChannelId] = [],
         scanForTuners: Bool = true) {
        
        self.isPlayerPaused = isPlayerPaused
        self.showAppNavigation = showAppNavigation
        self.selectedTab = selectedTab
        self.selectedChannel = selectedChannel
        self.recentChannelIds = recentChannelIds
        self.scanForTuners = scanForTuners
    }
}
