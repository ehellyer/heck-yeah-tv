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
        
        if not(savedBundles.isEmpty),
           not(savedBundles.contains(where: { $0.id == channelBundleId })) {
            
            let newBundleId = savedBundles.first!.id
            await MainActor.run {
                InjectedValues[\.sharedAppState].selectedChannelBundleId = newBundleId
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
            logDebug("Zero orphaned channels in the store.")
            return
        }
        
        logDebug("\(bundleEntries.count) orphaned channels found in the store.  Orphaned channels is normal operation when IPTV channels get removed or tuners are not accessible.")
        
        for bundleEntry in bundleEntries {
            let channelFetchDescriptor = ChannelPredicate(fetchLimit: 1, channelId: bundleEntry.channelId).fetchDescriptor()
            if let resolvedChannel = try? context.fetch(channelFetchDescriptor).first  {
                logDebug("Resolved orphaned channel: \(resolvedChannel.title)")
                bundleEntry.channel = resolvedChannel
            } else {
                logDebug("Unable to resolve orphaned channel for bundle entry: \(bundleEntry.sortHint) (<- sort hint)")
            }
        }
        
        try context.saveChangesIfNeeded()
    }
    
    // There must be at least one channel bundle, if one does not yet exist, we add the default.
    func checkDefaultChannelBundle() async throws -> Bool {
        let descriptor = ChannelBundlePredicate().fetchDescriptor()
        let channelBundles = try context.fetch(descriptor)
        let needsDefaultChannels: Bool = channelBundles.isEmpty
        
        if needsDefaultChannels {
            let channelBundle = ChannelBundle(id: AppKeys.Application.defaultChannelBundleId,
                                              name: "My Channel Bundle",
                                              channels: [])
            context.insert(channelBundle)
            try context.saveChangesIfNeeded()
        }
        
        return needsDefaultChannels
    }
    
    func addDefaultChanels() async throws {
        let descriptor = ChannelBundlePredicate(bundleId: AppKeys.Application.defaultChannelBundleId).fetchDescriptor()
        let channelBundles = try context.fetch(descriptor)
        guard let channelBundle = channelBundles.first else {
            logError("Default ChannelBundle not found.  Unable to add default channels.")
            return
        }
        
        if  let url = Bundle.main.url(forResource: "DefaultChannels", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let channelIds: [ChannelId] = try? JSONDecoder().decode([ChannelId] .self, from: data) {
            
            for channelId in channelIds {
                let channelDescriptor = ChannelPredicate(channelId: channelId).fetchDescriptor()
                let channel: Channel? = try context.fetch(channelDescriptor).first
                if let channel = channel {
                    let bundleEntry = BundleEntry(channel: channel, channelBundle: channelBundle)
                    context.insert(bundleEntry)
                }
            }
        }
        
        try context.saveChangesIfNeeded()
    }
}
