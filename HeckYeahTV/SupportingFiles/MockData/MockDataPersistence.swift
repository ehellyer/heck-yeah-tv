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
final class MockDataPersistence {
    
    private(set) var context: ModelContext
    
    init(appState: any AppStateProvider) {
        
        let schema = Schema(versionedSchema: HeckYeahSchema.self)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
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

            let mockChannels: [IPTVChannel] = try loadMockDataFromFile(fileName: "MockIPTVChannels", ext: "json")
            mockChannels.forEach(context.insert)
            logDebug("\(mockChannels.count) channels loaded")
            
            let mockCountries: [IPTVCountry] = try loadMockDataFromFile(fileName: "MockCountries", ext: "json")
            mockCountries.forEach(context.insert)
            logDebug("\(mockCountries.count) countries loaded")
            
            let mockTuners: [HDHomeRunServer] = try loadMockDataFromFile(fileName: "MockTunerDevices", ext: "json")
            mockTuners.forEach(context.insert)
            logDebug("\(mockTuners.count) tuners loaded")
            
            //Dev Note: IPTVChannel & IPTVCategory M:M relationships are setup in the MockIPTVChannels.json file.
            let mockCategories: [IPTVCategory] = try loadMockDataFromFile(fileName: "MockCategories", ext: "json")
            mockCategories.forEach(context.insert)
            logDebug("\(mockCategories.count) categories loaded")
            
            let mockFavorites: [IPTVFavorite] = try loadMockDataFromFile(fileName: "MockFavorites", ext: "json")
            mockFavorites.forEach(context.insert)
            logDebug("\(mockFavorites.count) favorites loaded")
            
            //Setup favorite relationships
            mockFavorites.forEach { fav in
                mockChannels.first(where: { $0.id == fav.id })?.favorite = fav
            }

            //Dev note: IPTVChannel & Guide M:M relationships are setup in the MockGuide.json file.
            let mockGuides: [Guide] = try loadMockDataFromFile(fileName: "MockGuides", ext: "json")
            mockGuides.forEach(context.insert)
            logDebug("\(mockGuides.count) guides loaded")
            
            do {
                try context.save()
                logDebug("MockDataPersistence Init completed: Mock data loaded into in-memory store.")
            } catch {
                throw MockDataPersistenceError.contextSaveFailed(underlyingError: error)
            }
        } catch {
            logDebug("Failed to load Mock json into SwiftData in-memory context.  Error: \(error.localizedDescription)")
        }
    }
}
