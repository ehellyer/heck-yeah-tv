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

    init(isPlayerPaused: Bool = false,
         showAppMenu: Bool = false,
         showChannelPrograms: ChannelProgram? = nil,
         selectedTab: AppSection = .guide,
         selectedChannel: ChannelId? = nil,
         recentChannelIds: [ChannelId] = [],
         scanForTuners: Bool = true,
         selectedChannelBundle: ChannelBundleId = AppKeys.Application.defaultChannelBundleId,
         dateLastGuideFetch: Date? = nil) {
        
        self.isPlayerPaused = isPlayerPaused
        self.showAppMenu = showAppMenu
        self.showChannelPrograms = showChannelPrograms
        self.selectedTab = selectedTab
        self.selectedChannel = selectedChannel
        self.recentChannelIds = recentChannelIds
        self.scanForTuners = scanForTuners
        self.selectedChannelBundle = selectedChannelBundle
        self.dateLastGuideFetch = dateLastGuideFetch
    }
    
    var isPlayerPaused: Bool
    var showAppMenu: Bool
    var showChannelPrograms: ChannelProgram?
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
    var selectedChannelBundle: ChannelBundleId
    var dateLastGuideFetch: Date?

}
