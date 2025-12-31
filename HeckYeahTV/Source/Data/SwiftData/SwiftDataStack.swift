//
//  DataPersistence.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import SQLite3

@MainActor
final class SwiftDataStack {
    
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
            // always upserted into the store on every cold application start or by a manual refresh call.
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try _rootURL.setResourceValues(resourceValues)
            logDebug("HeckYeahTV persistence root URL: \(_rootURL.path)")
            
            var _storeURL = _rootURL.appending(path: "GuideStore", directoryHint: .notDirectory)
            _storeURL.appendPathExtension("sqlite")
            storeURL = _storeURL
            logDebug("HeckYeahTV persistent store URL: \(_storeURL.path)")
            
            if Self.isLegacyUnversionedStore(at: _storeURL) {
                logWarning("Detected legacy unversioned store. Deleting and recreating with versioned schema...")
                try Self.deletePersistentStore(at: _storeURL)
                logDebug("Legacy store deleted successfully.")
            }
            
            let schema = Schema(versionedSchema: HeckYeahSchema.self)
            let modelConfig = ModelConfiguration(schema: schema,
                                                 url: self.storeURL,
                                                 cloudKitDatabase: .none)
            
            container = try ModelContainer(for: schema,
                                           migrationPlan: UpgradeSchemaMigrationPlan.self,
                                           configurations: [modelConfig])
            
            viewContext = ModelContext(container)
            viewContext.autosaveEnabled = true
            
            try Self.updateSchemaVersionTable(context: viewContext)
            try Self.checkDefaultChannelBundle(context: viewContext)
        } catch {
            logFatal("Failed to initialize GuideStore: \(error)")
        }
    }
    
    // Inserts or updates the schema version number into the model SchemaVersion for debug purposes when looking directly at the store via other dev tools.
    private static func updateSchemaVersionTable(context: ModelContext) throws {
        // Causes an insert or update because the SchemaVersion model has an ID property that is determined in the models initializer.
        context.insert(SchemaVersion())
        if context.hasChanges {
            try context.save()
        }
    }
    
    // There must be at least one channel bundle, if one does not yet exist, we add the default.
    private static func checkDefaultChannelBundle(context: ModelContext) throws {
        let descriptor = FetchDescriptor<ChannelBundle>()
        let count = try context.fetchCount(descriptor)
        if count == 0 {
            context.insert(ChannelBundle(id: UserDefaults.selectedChannelBundle,
                                         name: "Default",
                                         channelIds: []))
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    /// Check if the store at the given URL is a legacy unversioned store.
    /// Returns true if the store exists but doesn't have versioned schema.
    private static func isLegacyUnversionedStore(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        
        var db: OpaquePointer?
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            logWarning("Could not open store to check version")
            return false
        }
        defer { sqlite3_close(db) }
        var statement: OpaquePointer?
        let query = "SELECT ZVERSION FROM ZSCHEMAVERSION LIMIT 1"
        
        // If ZSCHEMAVERSION with column ZVERSION doesn't exist, it's a legacy store.
        let isLegacyStore = sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK
        return isLegacyStore
    }
    
    /// Delete the persistent store and all related files (.sqlite, .sqlite-shm, .sqlite-wal)
    private static func deletePersistentStore(at url: URL) throws {
        let fileManager = FileManager.default
        
        // Delete main store file
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        
        // Delete WAL file
        let walURL = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
        if fileManager.fileExists(atPath: walURL.path) {
            try fileManager.removeItem(at: walURL)
        }
        
        // Delete SHM file
        let shmURL = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
        if fileManager.fileExists(atPath: shmURL.path) {
            try fileManager.removeItem(at: shmURL)
        }
    }
    
    /// MainActor singleton instance.
    static let shared = SwiftDataStack()
    
    /// Model Container.
    let container: ModelContainer
    
    /// MainActor UI ModelContext.  (Autosave enabled)
    let viewContext: ModelContext
    
    /// URL of the persistent store, can be used to build ModelConfiguration.
    let storeURL: URL
}
