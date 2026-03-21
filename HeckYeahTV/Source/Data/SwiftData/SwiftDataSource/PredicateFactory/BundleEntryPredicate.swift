//
//  BundleEntryPredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/21/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

struct BundleEntryPredicate {
    
    /// Initialize with predicate values that will be AND together in the final predicate.
    init(bundleEntryIds: [BundleEntryId]? = nil,
         channelId: ChannelId? = nil,
         channelBundleId: ChannelBundleId? = nil,
         deviceId: HDHomeRunDeviceId? = nil,
         hasChannel: Bool? = nil,
         showFavoritesOnly: Bool = false) {
        self.bundleEntryIds = bundleEntryIds
        self.channelId = channelId
        self.channelBundleId = channelBundleId
        self.deviceId = deviceId
        self.hasChannel = hasChannel
        self.showFavoritesOnly = showFavoritesOnly
    }
    
    /// Returns a fetch descriptor with all the supplied criteria.   A sort descriptor is included on `BundleEntry`.sortHint ordered forward.
    func fetchDescriptor() -> FetchDescriptor<BundleEntry> {
        var descriptor = FetchDescriptor<BundleEntry>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        return descriptor
    }
    
    /// Returns a sort descriptor on `BundleEntry`.name ordered forward.
    func sortDescriptor() -> [SortDescriptor<BundleEntry>] {
        return [SortDescriptor<BundleEntry>(\.sortHint, order: .forward)]
    }
    
    /// Returns the predicate with the criteria values AND together.
    func predicate() -> Predicate<BundleEntry> {
        
        var conditions: [Predicate<BundleEntry>] = []
        
        if let bundleEntryIds, not(bundleEntryIds.isEmpty) {
            conditions.append(
                #Predicate<BundleEntry> { bundleEntry in
                    bundleEntryIds.contains(bundleEntry.id)
                }
            )
        }
        
        if let channelId {
            conditions.append( #Predicate<BundleEntry> { $0.channel?.id == channelId })
        }

        if let channelBundleId {
            conditions.append( #Predicate<BundleEntry> { $0.channelBundle.id == channelBundleId })
        }
        
        if let deviceId {
            conditions.append( #Predicate<BundleEntry> { $0.channel?.deviceId == deviceId })
        }
        
        if let hasChannel {
            if hasChannel {
                conditions.append(#Predicate<BundleEntry> { $0.channel != nil })
            } else {
                conditions.append(#Predicate<BundleEntry> { $0.channel == nil })
            }
        }
        
        if showFavoritesOnly {
            conditions.append( #Predicate<BundleEntry> { $0.isFavorite == true })
        }
        
        // Combine conditions using '&&' (AND)
        if conditions.isEmpty {
            return #Predicate { _ in true } // Return a predicate that always evaluates to true if no conditions
        } else {
            let compoundPredicate = conditions.reduce(#Predicate { _ in true }) { current, next in
                #Predicate { current.evaluate($0) && next.evaluate($0) }
            }
            return compoundPredicate
        }
    }
    
    //MARK: - Private API
    
    private var bundleEntryIds: [BundleEntryId]?
    private var channelId: ChannelId?
    private var channelBundleId: ChannelBundleId?
    private var deviceId: HDHomeRunDeviceId?
    private var hasChannel: Bool?
    private var showFavoritesOnly: Bool
}
