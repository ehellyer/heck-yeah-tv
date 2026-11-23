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
    func resetSelectedChannelBundleIdIfMissing() async throws {
        let selectedBundleId = await MainActor.run {
            InjectedValues[\.sharedAppState].selectedChannelBundleId
        }
        
        let fetchDescriptor = ChannelBundlePredicate().fetchDescriptor()
        let savedBundles = try context.fetch(fetchDescriptor)
        
        if not(savedBundles.isEmpty),
           not(savedBundles.contains(where: { $0.id == selectedBundleId })) {
            
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
    func reconnectOrphanedBundleEntries() async throws {
        
        let orphanedEntriesDescriptor = BundleEntryPredicate(hasChannel: false).fetchDescriptor()
        let orphanedEntries: [BundleEntry] = try context.fetch(orphanedEntriesDescriptor)
        
        guard orphanedEntries.isEmpty == false else {
            logDebug("Zero orphaned channels in the store.")
            return
        }
        
        logDebug("\(orphanedEntries.count) orphaned channels found in the store.  Orphaned channels is normal operation when IPTV channels get removed or tuners are not accessible.")
        
        for bundleEntry in orphanedEntries {
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
    
    /// Creates the default `ChannelBundle` if no channel bundles exist yet.
    ///
    /// There must always be at least one channel bundle. On first launch after install none exist,
    /// so a default bundle is inserted and saved to improve the first-run experience.
    ///
    /// - Returns: `true` if the default channel bundle was created, `false` if one or more bundles already existed.
    func createDefaultChannelBundleIfNeeded() async throws -> Bool {
        let descriptor = ChannelBundlePredicate().fetchDescriptor()
        let channelBundles = try context.fetch(descriptor)
        let didCreateDefaultBundle: Bool = channelBundles.isEmpty
        
        if didCreateDefaultBundle {
            let channelBundle = ChannelBundle(id: AppKeys.Application.defaultChannelBundleId,
                                              name: "My Channel Bundle",
                                              channels: [])
            context.insert(channelBundle)
            try context.saveChangesIfNeeded()
        }
        
        return didCreateDefaultBundle
    }
    
    /// Adds the channels listed in the bundled `DefaultChannels.json` file to the default `ChannelBundle`.
    ///
    /// Channel IDs that are not present in the store are skipped. If the default bundle cannot be
    /// found, an error is logged and no channels are added.
    ///
    /// - Throws: Any fetch or save error propagated from the actor's `ModelContext`.
    func addDefaultChannelsToDefaultBundle() async throws {
        let descriptor = ChannelBundlePredicate(bundleId: AppKeys.Application.defaultChannelBundleId).fetchDescriptor()
        let defaultBundles = try context.fetch(descriptor)
        guard let defaultBundle = defaultBundles.first else {
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
                    let bundleEntry = BundleEntry(channel: channel, channelBundle: defaultBundle)
                    context.insert(bundleEntry)
                }
            }
        }
        
        try context.saveChangesIfNeeded()
    }
}
