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
            swiftDataStoreURL = _storeURL
            logDebug("HeckYeahTV persistent store URL: \(_storeURL.path)")
            
            // Dev mode: Nuke the store if it's from "yesterday's schema."
            // Because writing migration code for every little tweak during v1.0 development is nobody's idea of fun.
            // Once we ship, we'll play by the rules. Until then? Scorched earth policy. 🔥
            if Self.isLegacyStore(at: _storeURL) {
                logWarning("Detected legacy store. Deleting and recreating with versioned schema...")
                try Self.deletePersistentStore(at: _storeURL)
                logDebug("Legacy store deleted successfully.")
            }
            
            // Dev note: HeckYeahSchema always points to latest schema, which holds the version number and model definitions.
            let schema = Schema(versionedSchema: HeckYeahSchema.self)
            let modelConfig = ModelConfiguration(schema: schema,
                                                 url: self.swiftDataStoreURL,
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
        // Causes an insert or update because the SchemaVersion model has an ID property that is pre-determined in the models initializer.
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
    
    /// MainActor singleton instance.
    static let shared = SwiftDataStack()
    
    /// Model Container.
    let container: ModelContainer
    
    /// MainActor UI ModelContext.  (Autosave enabled)
    let viewContext: ModelContext
    
    /// URL of the persistent store, can be used to build ModelConfiguration.
    let swiftDataStoreURL: URL
    
    /// URL to the file stores for the HeckYeahTVApp
    let appFileStoreRootURL: URL
}

/// Because sometimes you just gotta get down and dirty with SQLite.
/// When SwiftData's fancy APIs aren't enough, we roll up our sleeves and speak directly to the database gods.
/// (Spoiler: They like to 'byte' and they're not always friendly.)
extension SwiftDataStack {
    
    /// Checks if this database is older than your last app update (it probably is).
    /// Returns true if the store is using that ancient schema from two versions ago that we all agreed to forget about.
    private static func isLegacyStore(at url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return false
        }
        
        let verificationUUID = UUID(uuidString: "fe7046c4-c15d-4e78-ba5b-50378a50c0b1")! // Our secret handshake with the database.
        let devBuildVersion = "0.0.0" // The magic version that says "I'm still in development, feel free to delete me."
        
        var db: OpaquePointer? // OpaquePointer: Because nothing says "modern Swift" like a C pointer from the 90s.
        guard sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            logWarning("Could not open store to check version.")
            return true // Can't check the version if we can't even open the door.
        }
        defer { sqlite3_close(db) } // Always close what you open. It's not just good manners, it's the law.
        
        var statement: OpaquePointer?
        let query = "SELECT ZID, ZVERSION FROM ZSCHEMAVERSION LIMIT 1" // LIMIT 1 because there's only one schema version. If there's more than one, we've got bigger problems.
        
        var isLegacyStore = false
        
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            logWarning("Error preparing SwiftData schema version query.  Error: \(errorMessage)")
            isLegacyStore = true
            return isLegacyStore
        }
        
        guard sqlite3_step(statement) == SQLITE_ROW else {
            logWarning("No data found in ZSCHEMAVERSION during SwiftData schema verification. Assuming legacy store.")
            isLegacyStore = true
            return isLegacyStore
        }
        
        let blobPointer = sqlite3_column_blob(statement, 0)
        let byteCount = Int(sqlite3_column_bytes(statement, 0))
        
        let id = uuidFromBlob(pointer: blobPointer, byteCount: byteCount)
        let version = String(cString: sqlite3_column_text(statement, 1))
        
        let isDevBuildVersion = devBuildVersion == version || HeckYeahSchema.versionIdentifier.description == devBuildVersion

        isLegacyStore = (id != verificationUUID || isDevBuildVersion)
        
        return isLegacyStore
    }
    
    /// Converts a blob of bytes into a UUID, because apparently UUIDs are too fancy to be stored as strings.
    /// Apple's like "let's store it as 16 random bytes!" and we're like "...sure, why not?"
    private static func uuidFromBlob(pointer: UnsafeRawPointer?, byteCount: Int) -> UUID? {

        guard byteCount == 16, let pointer else {
            return nil
        }
        let uuidData = Data(bytes: pointer, count: byteCount)
        let uuidBytes = uuidData.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> uuid_t in
            let bytes = pointer.load(as: uuid_t.self)
            return bytes
        }
        
        return UUID(uuid: uuidBytes)
    }
    
    /// Nukes the persistent store from orbit. It's the only way to be sure.
    /// Deletes the main .sqlite file and its clingy friends (.sqlite-shm, .sqlite-wal).
    /// Because apparently one file wasn't enough - SQLite brought the whole squad.
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
}
