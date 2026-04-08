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
        
        let fetchDescriptor = ChannelBundlePredicate().fetchDescriptor()
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
        
        let orphanedChannelDescriptor = BundleEntryPredicate(hasChannel: false).fetchDescriptor()
        let bundleEntries: [BundleEntry] = try context.fetch(orphanedChannelDescriptor)
        
        guard bundleEntries.isEmpty == false else {
            logDebug("\(bundleEntries.count) orphaned channels found in the store.  Orphaned channels is normal operation when IPTV channels get removed or tuners are not accessible.")
            return
        }
        logDebug("Zero orphaned channels in the store.")
        
        var channelDescriptor = ChannelPredicate().fetchDescriptorNoSort()
        channelDescriptor.fetchLimit = 1
        for bundleEntry in bundleEntries {
            
            let channelPredicate = #Predicate<Channel> { $0.id == bundleEntry.channelId }
            channelDescriptor.predicate = channelPredicate
            
            if let resolvedChannel = try? context.fetch(channelDescriptor).first  {
                logDebug("Resolved orphaned channel: \(resolvedChannel.title)")
                bundleEntry.channel = resolvedChannel
            } else {
                logDebug("Unable to resolve orphaned channel for bundle entry: \(bundleEntry.sortHint) (<- sort hint)")
            }
        }
        try context.saveChangesIfNeeded()
    }
}
