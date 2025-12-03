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
    var showFavoritesOnly: Bool
    var selectedCountry: CountryCode?
    var selectedCategory: CategoryId?
    var searchTerm: String?
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
         showFavoritesOnly: Bool = false,
         selectedCountry: CountryCode? = nil,
         selectedCategory: CategoryId? = nil,
         searchTerm: String? = nil,
         selectedTab: AppSection = .channels,
         selectedChannel: ChannelId? = nil,
         recentChannelIds: [ChannelId] = [],
         scanForTuners: Bool = true) {
        
        self.isPlayerPaused = isPlayerPaused
        self.showAppNavigation = showAppNavigation
        self.showFavoritesOnly = showFavoritesOnly
        self.selectedCountry = selectedCountry
        self.selectedCategory = selectedCategory
        self.searchTerm = searchTerm
        self.selectedTab = selectedTab
        self.selectedChannel = selectedChannel
        self.recentChannelIds = recentChannelIds
        self.scanForTuners = scanForTuners
    }
}
