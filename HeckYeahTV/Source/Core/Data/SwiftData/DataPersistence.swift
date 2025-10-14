//
//  DataPersistence.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
final class DataPersistence {

    /// Private init due to shared singleton instance.
    private init() {
        do {
            
#if os(tvOS)
            //tvOS has restrictions on where we can write files to.
            var searchPathDirectory: FileManager.SearchPathDirectory = .cachesDirectory
#else
            var searchPathDirectory: FileManager.SearchPathDirectory = .applicationSupportDirectory
#endif
            
            guard var _rootURL = FileManager.default.urls(for: searchPathDirectory,
                                                          in: FileManager.SearchPathDomainMask.userDomainMask).first else {
                fatalError("Failed to initialize persistence store: Could not build application support directory root URL.")
            }
            
            _rootURL.append(component: "HeckYeahTV")
            _rootURL.append(component: "ChannelData")
            try FileManager.default.createDirectory(atPath: _rootURL.path, withIntermediateDirectories: true)
            
            // Exclude from backups.  At this time I would prefer to let the store rebuild itself.
            // Users would lose favorite channels and recently played channels, but the channels themselves are
            // always insert or updated (upserted) into the store on every cold application start.
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try _rootURL.setResourceValues(resourceValues)
            print("HeckYeahTV persistence root URL: \(_rootURL.path)")
            
            var _storeURL = _rootURL.appending(path: "GuideStore", directoryHint: .notDirectory)
            _storeURL.appendPathExtension("sqlite")
            storeURL = _storeURL
            print("HeckYeahTV persistent store URL: \(_storeURL.path)")
            
            let config = ModelConfiguration(url: self.storeURL)
            container = try ModelContainer(for: IPTVChannel.self, IPTVChannelMap.self, configurations: config)
            viewContext = ModelContext(container)
            viewContext.autosaveEnabled = true
        } catch {
            fatalError("Failed to initialize GuideStore: \(error)")
        }
    }

    /// MainActor singleton instance.
    static let shared = DataPersistence()

    /// Model Container.
    let container: ModelContainer
    
    /// MainActor UI ModelContext.  (Autosave enabled)
    let viewContext: ModelContext
    
    /// URL of the persistent store, can be used to build ModelConfiguration.
    let storeURL: URL
}
