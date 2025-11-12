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
    var isGuideVisible: Bool
    var showFavoritesOnly: Bool
    var selectedTab: TabSection
    var selectedChannel: ChannelId?
    
    init(isPlayerPaused: Bool = false,
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
