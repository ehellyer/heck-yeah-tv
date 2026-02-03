//
//  MockSwiftDataStack.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/6/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

/// Errors that can occur during mock data loading
enum MockDataPersistenceError: LocalizedError {
    case fileNotFound(fileName: String, extension: String)
    case dataLoadingFailed(fileName: String, underlyingError: Error)
    case contextSaveFailed(underlyingError: Error)
    case invalidData(fileName: String, reason: String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName, let ext):
            return "File not found: \(fileName).\(ext)"
        case .dataLoadingFailed(let fileName, let error):
            return "Failed to load data from \(fileName): \(error.localizedDescription)"
        case .contextSaveFailed(let error):
            return "Failed to save mock data context: \(error.localizedDescription)"
        case .invalidData(let fileName, let reason):
            return "Invalid data in \(fileName): \(reason)"
        }
    }
}

/// Builds an IN-MEMORY mock SwiftDataStack for previews.
@MainActor
final class MockSwiftDataStack: SwiftDataStackProvider {
    
    
//MARK: - Internal API - SwiftDataProvider implementation

    private init() {
        
        let schema = Schema(versionedSchema: HeckYeahSchema.self)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        
        self.container = container
        self.viewContext = ModelContext(container)

        loadMockData()
    }
    
    private func loadMockDataFromFile<T: JSONSerializable>(fileName: String, ext: String) throws -> T {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else {
            logDebug("Failed to load \(fileName).\(ext).  Exiting.")
            throw MockDataPersistenceError.fileNotFound(fileName: fileName, extension: ext)
        }
        
        do {
            let data = try Data(contentsOf: url)
            let models = try T.initialize(jsonData: data)
            return models
        } catch {
            throw MockDataPersistenceError.dataLoadingFailed(fileName: "\(fileName).\(ext)", underlyingError: error)
        }
    }
    
    private func loadMockData() {
        do {
            logDebug("MockDataPersistence Init starting...")
            
            let mockCountries: [Country] = try loadMockDataFromFile(fileName: "MockCountries", ext: "json")
            mockCountries.forEach(viewContext.insert)
            logDebug("\(mockCountries.count) countries loaded")
            
            let mockTuners: [HomeRunDevice] = try loadMockDataFromFile(fileName: "MockTunerDevices", ext: "json")
            mockTuners.forEach(viewContext.insert)
            logDebug("\(mockTuners.count) tuners loaded")
            
            //Dev Note: Channel & ProgramCategory M:M relationships are setup in the MockChannels.json file.
            let mockCategories: [ProgramCategory] = try loadMockDataFromFile(fileName: "MockCategories", ext: "json")
            mockCategories.forEach(viewContext.insert)
            logDebug("\(mockCategories.count) categories loaded")

            let mockChannelBundles: [ChannelBundle] = try loadMockDataFromFile(fileName: "MockChannelBundles", ext: "json")
            mockChannelBundles.forEach(viewContext.insert)
            logDebug("\(mockChannelBundles.count) channel bundles loaded")
            
            let mockChannels: [Channel] = try loadMockDataFromFile(fileName: "MockChannels", ext: "json")
            mockChannels.forEach(viewContext.insert)
            logDebug("\(mockChannels.count) channels loaded")

            let mockChannelPrograms: [ChannelProgram] = try loadMockDataFromFile(fileName: "MockChannelPrograms", ext: "json")
            mockChannelPrograms.forEach(viewContext.insert)
            logDebug("\(mockChannelPrograms.count) channel programs loaded")
            
            
            let favorites: [String] = ["chan.local.002",
                                       "chan.local.001",
                                       "e19323684c285f0921bfb2cdde9efa96bfcf408b13d25a143f5d06b16e52a417",
                                       "6d01fee6b9c711b98dca6b59682eeda75e67e4f428abed6aa28b890d993fe82c",
                                       "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"]
            let channelBundle: ChannelBundle = mockChannelBundles.first!
            mockChannels[0...20].forEach { channel in
                let channelId: ChannelId = channel.id
                
                let bundleEntry = BundleEntry(channel: channel,
                                              channelBundle: channelBundle,
                                              sortHint: channel.sortHint,
                                              isFavorite: favorites.contains(channelId))
                viewContext.insert(bundleEntry)
            }
            
            var appState: AppStateProvider = InjectedValues[\.sharedAppState]
            appState.selectedChannelBundle = channelBundle.id
            
            do {
                try viewContext.save()
                logDebug("MockDataPersistence Init completed: Mock data loaded into in-memory store.")
            } catch {
                throw MockDataPersistenceError.contextSaveFailed(underlyingError: error)
            }
        } catch {
            logDebug("Failed to load Mock json into SwiftData in-memory context.  Error: \(error.localizedDescription)")
        }
    }

    
    /// MainActor singleton instance.
    static let shared = MockSwiftDataStack()
    
    /// Model Container.
    let container: ModelContainer
    
    /// MainActor UI ModelContext.  (Autosave enabled)
    let viewContext: ModelContext
}
