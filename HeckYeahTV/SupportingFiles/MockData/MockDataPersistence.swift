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
        let container = try! ModelContainer(for: IPTVChannel.self, IPTVCountry.self, HDHomeRunServer.self, configurations: config)
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
            let channelUrl = Bundle.main.url(forResource: "MockIPTVChannels", withExtension: "json")!
            let channelData = try Data(contentsOf: channelUrl)
            let mockChannels = try [IPTVChannel].initialize(jsonData: channelData)
            mockChannels.forEach(context.insert)

            let countryUrl = Bundle.main.url(forResource: "MockCountries", withExtension: "json")!
            let countryData = try Data(contentsOf: countryUrl)
            let mockCountries = try [IPTVCountry].initialize(jsonData: countryData)
            mockCountries.forEach(context.insert)

            let tunerUrl = Bundle.main.url(forResource: "MockTunerDevices", withExtension: "json")!
            let tunerData = try Data(contentsOf: tunerUrl)
            let mockTuners = try [HDHomeRunServer].initialize(jsonData: tunerData)
            mockTuners.forEach(context.insert)
            
            try context.save()
        } catch {
            logDebug("Failed to load Mock json into SwiftData in-memory context.  Error: \(error)")
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
