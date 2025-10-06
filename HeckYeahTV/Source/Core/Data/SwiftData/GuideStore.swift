//
//  GuideStore.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Observation
import SwiftUI

typealias ChannelId = String

@MainActor @Observable
final class GuideStore {
    
    @MainActor
    init() {
        let store = Persistence.shared
        
        self.modelContext =  ModelContext(store.container)
        self.modelContainer = store.container
    }

    private var modelContainer: ModelContainer
    private var modelContext: ModelContext
    
    @MainActor
    private func getFavoriteIds() throws -> [ChannelId] {
        let predicate = #Predicate<IPTVChannel> { $0.isFavorite }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.propertiesToFetch = [\.id]
        let favorites = try modelContext.fetch(descriptor).map(\.id)
        return favorites
    }
    
    @MainActor
    private func getPlayingChannel() throws -> IPTVChannel? {
        let predicate = #Predicate<IPTVChannel> { $0.isPlaying }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        let playingChannel = try modelContext.fetch(descriptor).first
        return playingChannel
    }
    
    @MainActor
    private func getPlayingChannelId() throws -> ChannelId? {
        let predicate = #Predicate<IPTVChannel> { $0.isPlaying }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.propertiesToFetch = [\.id]
        descriptor.fetchLimit = 1
        let playingChannelId = try modelContext.fetch(descriptor).map(\.id).first
        return playingChannelId
    }
    
    //MARK: - Internal API
    
    @MainActor
    var isPlaying: Bool = true
    
    @MainActor
    var isGuideVisible: Bool = false
    
    @MainActor
    var selectedChannel: IPTVChannel? {
        try? getPlayingChannel()
    }
    
    @MainActor
    var selectedTab: TabSection {
        get {
            return UserDefaults.lastTabSelected
        }
        set {
            UserDefaults.lastTabSelected = newValue
        }
    }
    
    @MainActor
    var showFavoritesOnly: Bool {
        get {
            return UserDefaults.showFavorites
        }
        set {
            UserDefaults.showFavorites = newValue
        }
    }
    
    @MainActor
    func getAllChannels() throws -> [IPTVChannel] {
        let descriptor = FetchDescriptor<IPTVChannel>(sortBy: [SortDescriptor(\.sortHint, order: .forward)])
        let channels = try modelContext.fetch(descriptor)
        return channels
    }
    
    @MainActor
    func setPlayingChannel(id: String) throws {
        /// There can only be one channel at a time playing, this code enforces that demand.
        let isPlayingPredicate = #Predicate<IPTVChannel> { $0.isPlaying }
        let isPlayingDescriptor = FetchDescriptor<IPTVChannel>(predicate: isPlayingPredicate)
        let channels = try modelContext.fetch(isPlayingDescriptor)
        
        let targetChannelPredicate = #Predicate<IPTVChannel> { $0.id == id }
        var targetChannelDescriptor = FetchDescriptor<IPTVChannel>(predicate: targetChannelPredicate)
        targetChannelDescriptor.fetchLimit = 1
        let targetChannel = try modelContext.fetch(targetChannelDescriptor).first
        
        for channel in channels {
            channel.isPlaying = false
        }
        targetChannel?.isPlaying = true
        
        try modelContext.save()
    }
    
    @MainActor
    func toggleFavorite(id: String) throws {
        let predicate = #Predicate<IPTVChannel> { $0.id == id }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let channel = try modelContext.fetch(descriptor).first {
            channel.isFavorite.toggle()
            try modelContext.save()
        }
    }
}
