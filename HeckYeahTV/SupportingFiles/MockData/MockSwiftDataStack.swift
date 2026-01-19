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
final class MockSwiftDataStack {
    
    
//MARK: - Internal API - SwiftDataControllable implementation

    init() {
        
        let schema = Schema(versionedSchema: HeckYeahSchema.self)
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        
        self.container = container
        self.viewContext = ModelContext(container)
        
        
#if os(tvOS)
        //tvOS has restrictions on where we can write store files to.  Thanks Apple.
        var searchPathDirectory: FileManager.SearchPathDirectory = .cachesDirectory
#else
        var searchPathDirectory: FileManager.SearchPathDirectory = .applicationSupportDirectory
#endif
        
        guard var _rootURL = FileManager.default.urls(for: searchPathDirectory,
                                                      in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            fatalError("Failed to initialize persistence store: Could not build application support directory root URL.")
        }
        
        _rootURL.append(component: "HeckYeahTV")

        self.appFileStoreRootURL = _rootURL
        self.swiftDataStoreURL = _rootURL
        
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

            let mockChannels: [Channel] = try loadMockDataFromFile(fileName: "MockChannels", ext: "json")
            mockChannels.forEach(viewContext.insert)
            logDebug("\(mockChannels.count) channels loaded")
            
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
            
            let mockFavorites: [Favorite] = try loadMockDataFromFile(fileName: "MockFavorites", ext: "json")
            mockFavorites.forEach(viewContext.insert)
            logDebug("\(mockFavorites.count) favorites loaded")
            
            //Setup favorite relationships
            mockFavorites.forEach { fav in
                mockChannels.first(where: { $0.id == fav.id })?.favorite = fav
            }
           
            let mockChannelBundles: [ChannelBundle] = try loadMockDataFromFile(fileName: "MockChannelBundles", ext: "json")
            mockChannelBundles.forEach(viewContext.insert)
            logDebug("\(mockChannelBundles.count) channel bundles loaded")

            
            let mockChannelPrograms: [ChannelProgram] = try loadMockDataFromFile(fileName: "MockChannelPrograms", ext: "json")
            mockChannelPrograms.forEach(viewContext.insert)
            logDebug("\(mockChannelPrograms.count) channel programs loaded")

            
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
    
    /// URL of the persistent store, can be used to build ModelConfiguration.
    let swiftDataStoreURL: URL
    
    /// URL to the file stores for the HeckYeahTVApp
    let appFileStoreRootURL: URL
}
