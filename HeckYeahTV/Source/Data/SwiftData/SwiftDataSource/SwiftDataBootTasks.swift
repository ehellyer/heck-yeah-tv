//
//  SwiftDataBootTasks.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/17/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

actor SwiftDataBootTasks {
    
    deinit {
        logDebug("Deallocated")
    }
    
    init(container: ModelContainer) {
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
    }
    
    private var batchCount: Int = 0
    private let batchSize: Int = 500
    private let context: ModelContext
    
    /// Ensures the `selectedChannelBundleId` stored in `AppStateProvider` refers to a bundle that
    /// still exists in the store.
    ///
    /// `selectedChannelBundleId` is persisted as a plain `ChannelBundleId` in `AppStateProvider` and
    /// is therefore not subject to SwiftData referential integrity. If the referenced bundle is
    /// deleted, the stale ID lingers indefinitely. This function detects that condition and resets
    /// the selection to the first available bundle (sorted alphabetically by name), keeping
    /// `AppStateProvider` in sync with the source of truth in SwiftData.
    ///
    /// - Throws: Any fetch error propagated from the actor's `ModelContext`.
    func alignSelectedChannelBundleId() async throws {
        let channelBundleId = await MainActor.run {
            InjectedValues[\.sharedAppState].selectedChannelBundleId
        }
        
        let sortDescriptor = [SortDescriptor<ChannelBundle>(\.name, order: .forward)]
        let fetchDescriptor = FetchDescriptor<ChannelBundle>(sortBy: sortDescriptor)
        let savedBundles = try context.fetch(fetchDescriptor)
        
        if not(savedBundles.contains(where: { $0.id == channelBundleId })) {
            let newBundleId = savedBundles.first!.id
            await MainActor.run {
                var appState = InjectedValues[\.sharedAppState]
                appState.selectedChannelBundleId = newBundleId
            }
        }
    }
    
    /// Reconnects orphaned `BundleEntry` records to their corresponding `Channel` in the store.
    ///
    /// A `BundleEntry` becomes orphaned when its `Channel` is deleted from the catalog. SwiftData
    /// nullifies the relationship (`.nullify` delete rule) rather than cascading the delete, leaving
    /// the entry intact but with `channel == nil`. When the channel is later re-added to the catalog,
    /// this function restores the relationship by matching each orphaned entry's `channelId` to the
    /// newly inserted `Channel`.
    ///
    /// The context is saved at the end via `saveChangesIfNeeded()`, so no save occurs if no
    /// relationships were restored.
    ///
    /// - Throws: Any fetch or save error propagated from the actor's `ModelContext`.
    func mapOrphanedBundleEntryWithChannel() async throws {
        let bundleEntryPredicate = #Predicate<BundleEntry> { $0.channel == nil }
        let bundleEntryDescriptor = FetchDescriptor<BundleEntry>(predicate: bundleEntryPredicate)
        
        var channelDescriptor = FetchDescriptor<Channel>()
        channelDescriptor.fetchLimit = 1
        
        let bundleEntries: [BundleEntry] = try context.fetch(bundleEntryDescriptor)
        for bundleEntry in bundleEntries {
            
            let channelPredicate = #Predicate<Channel> { $0.id == bundleEntry.channelId }
            channelDescriptor.predicate = channelPredicate
            
            if let resolvedChannel = try? context.fetch(channelDescriptor).first  {
                bundleEntry.channel = resolvedChannel
            }
        }
        try context.saveChangesIfNeeded()
    }
}
