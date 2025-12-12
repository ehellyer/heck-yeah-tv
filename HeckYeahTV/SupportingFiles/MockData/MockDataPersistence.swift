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
    
    init(appState: any AppStateProvider) {
        
        let schema = Schema(versionedSchema: HeckYeahSchema.self)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        loadMockData()
    }
    
    private func loadMockData() {
        do {
            logDebug("MockDataPersistence Init starting...")
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
            
            let categoriesUrl = Bundle.main.url(forResource: "MockCategories", withExtension: "json")!
            let categoriesData = try Data(contentsOf: categoriesUrl)
            let mockCategories = try [IPTVCategory].initialize(jsonData: categoriesData)
            mockCategories.forEach(context.insert)
            
            try context.save()
            logDebug("MockDataPersistence Init completed: Mock data loaded into in-memory store.")
        } catch {
            logDebug("Failed to load Mock json into SwiftData in-memory context.  Error: \(error)")
        }
    }
}
