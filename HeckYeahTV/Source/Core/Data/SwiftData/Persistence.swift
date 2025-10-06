//
//  Persistence.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
final class Persistence {

    /// Private init due to shared singleton instance.
    private init() {
        do {
            guard var _rootURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory,
                                                          in: FileManager.SearchPathDomainMask.userDomainMask).first else {
                fatalError("Failed to initialize persistence store: Could not get application support directory URL.")
            }
            
            _rootURL.append(component: "HeckYeahTV")
            _rootURL.append(component: "ChannelData")
            try FileManager.default.createDirectory(atPath: _rootURL.path, withIntermediateDirectories: true)
            rootURL = _rootURL
            
            print("HeckYeahTV persistence root URL: \(rootURL.path)")
            
            // Exclude from backups.  At this time I would prefer to let the store rebuild itself.
            // Users would lose favorite channels and recently played channels, but the channels themselves are
            // always insert or updated (upserted) into the store on every cold application start.
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try _rootURL.setResourceValues(resourceValues)
            
            var _storeURL = rootURL.appending(path: "GuideStore", directoryHint: .notDirectory)
            _storeURL.appendPathExtension("sqlite")
            storeURL = _storeURL
            
            let config = ModelConfiguration(url: self.storeURL)
            container = try ModelContainer(for: IPTVChannel.self, configurations: config)
            viewContext = ModelContext(container)
            viewContext.autosaveEnabled = true
        } catch {
            fatalError("Failed to initialize GuideStore: \(error)")
        }
    }

    /// MainActor singleton instance.
    static let shared = Persistence()

    /// Model Container.
    let container: ModelContainer
    
    /// MainActor UI Context.
    let viewContext: ModelContext

    /// URL to the directory containing the persistent store.
    let rootURL: URL
    
    /// URL of the persistent store.
    let storeURL: URL
    
    /// Returns a new context for batch work in the model container
    /// - Parameter autosave: A Boolean to enable or disable autosave on the context after mutation.  Autosave is disabled by default.
    /// - Returns: A new instance of ModelContext base on the current container configuration.
    func makeContext(autosave: Bool = false) -> ModelContext {
        let ctx = ModelContext(container)
        ctx.autosaveEnabled = autosave
        return ctx
    }
}
