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
        reloadChannels(showFavoritesOnly: appState.showFavoritesOnly)
    }
    
    func reloadChannels(showFavoritesOnly: Bool) {
        loadChannels(showFavoritesOnly: showFavoritesOnly)
        buildChannelMap()
    }
    
    private func loadMockData() {
        do {
            struct MockChannel: JSONSerializable {
                let id: String
                let sortHint: String
                let title: String
                let number: String?
                let url: URL
                let logoURL: URL?
                let quality: StreamQuality
                let hasDRM: Bool
                let source: ChannelSource
                let isFavorite: Bool
            }
            
            // Load mock data from JSON file
            let url = Bundle.main.url(forResource: "MockIPTVChannels", withExtension: "json")!
            let data = try Data(contentsOf: url)
            
            // Decode MockChannel array from JSON file
            let mockChannels = try [MockChannel].initialize(jsonData: data)
            
            // Convert mock channels to IPTVChannel instances
            for mock in mockChannels {
                let channel = IPTVChannel(id: mock.id,
                                          sortHint: mock.sortHint,
                                          title: mock.title,
                                          number: mock.number,
                                          url: mock.url,
                                          logoURL: mock.logoURL,
                                          quality: mock.quality,
                                          hasDRM: mock.hasDRM,
                                          source: mock.source,
                                          isFavorite: mock.isFavorite)
                context.insert(channel)
            }
            
            try context.save()
        } catch {
            logDebug("MOCK UTILITY: Failed to load MockIPTVChannels.json.  Error: \(error)")
        }
    }
    
    private func loadChannels(showFavoritesOnly: Bool) {
        var channelsDescriptor: FetchDescriptor<IPTVChannel> = FetchDescriptor<IPTVChannel>(
            sortBy: [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
        )
        channelsDescriptor.predicate = (showFavoritesOnly ? (#Predicate<IPTVChannel> { $0.isFavorite == true }) : nil)
        self.channels = (try? context.fetch(channelsDescriptor)) ?? []
    }

    private func buildChannelMap() {
        let map: [ChannelId] = channels.map { $0.id }
        channelMap = ChannelMap(map: map)
    }
}
