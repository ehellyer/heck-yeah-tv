//
//  MockChannelLoader.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/6/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

/// Builds an IN-MEMORY mock DataPersistence for previews.
@MainActor
final class MockDataPersistence {
    
    private(set) var context: ModelContext
    private(set) var channels: [IPTVChannel] = []
    private(set) var channelMap: ChannelMap = ChannelMap(map: [])
    
    init(appState: any AppStateProvider) {
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: IPTVChannel.self, configurations: config)
        context = ModelContext(container)
        loadMockData()
        reloadChannels(appState: appState)
    }
    
    func reloadChannels(appState: any AppStateProvider) {
        loadChannels(appState: appState)
        buildChannelMap()
    }
    
    private func loadMockData() {
        do {
            // Read mock data from JSON file
            let url = Bundle.main.url(forResource: "MockIPTVChannels", withExtension: "json")!
            let data = try Data(contentsOf: url)
            
            // Decode Array<IPTVChannel> from JSON file.
            let mockChannels = try [IPTVChannel].initialize(jsonData: data)
            
            // Load IPTVChannel instances into in-memory context.
            mockChannels.forEach(context.insert)
            
            try context.save()
        } catch {
            logDebug("Failed to load MockIPTVChannels.json into SwiftData in-memory context.  Error: \(error)")
        }
    }
    
    private func loadChannels(appState: any AppStateProvider) {
        var channelsDescriptor: FetchDescriptor<IPTVChannel> = FetchDescriptor<IPTVChannel>(
            sortBy: [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
        )
        channelsDescriptor.predicate = (appState.showFavoritesOnly ? (#Predicate<IPTVChannel> { $0.isFavorite == true }) : nil)
        self.channels = (try? context.fetch(channelsDescriptor)) ?? []
    }

    private func buildChannelMap() {
        let map: [ChannelId] = channels.map { $0.id }
        channelMap = ChannelMap(map: map)
    }
}
