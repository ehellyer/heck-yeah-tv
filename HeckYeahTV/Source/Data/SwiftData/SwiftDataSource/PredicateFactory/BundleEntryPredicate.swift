//
//  BundleEntryPredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/21/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

/// Query builder for `BundleEntry` models — because finding the right entry shouldn't feel like channel surfing.
///
/// Non-nil filter criteria are AND-ed together; all must match.
struct BundleEntryPredicate {

    /// Sets up optional filter criteria. Non-nil values gang up with logical AND — all must agree or no dice.
    /// - Parameters:
    ///   - fetchLimit: Cap on how many results you get back. Leave `nil` to live without limits.
    ///   - bundleEntryIds: Match entries with any of these IDs. Like a VIP guest list.
    ///   - channelId: Match entries tied to a specific channel.
    ///   - channelBundleId: Match entries belonging to a specific bundle.
    ///   - deviceId: Match entries whose channel belongs to a specific device.
    ///   - hasChannel: `true` = has a channel, `false` = channel ghosted (removed from catalog), `nil` = don't care.
    ///   - showFavoritesOnly: When `true`, only the channels you actually like make the cut.
    init(fetchLimit: Int? = nil,
         bundleEntryIds: [BundleEntryId]? = nil,
         channelId: ChannelId? = nil,
         channelBundleId: ChannelBundleId? = nil,
         deviceId: HDHomeRunDeviceId? = nil,
         hasChannel: Bool? = nil,
         showFavoritesOnly: Bool = false) {
        self.fetchLimit = fetchLimit
        self.bundleEntryIds = bundleEntryIds
        self.channelId = channelId
        self.channelBundleId = channelBundleId
        self.deviceId = deviceId
        self.hasChannel = hasChannel
        self.showFavoritesOnly = showFavoritesOnly
    }

    /// Returns a fetch descriptor sorted by `sortHint` ascending — the path of least surprise.
    func fetchDescriptorDefaultSort() -> FetchDescriptor<BundleEntry> {
        var descriptor = FetchDescriptor<BundleEntry>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Returns a fetch descriptor with custom sort — for when `sortHint` just isn't your vibe.
    /// - Parameter sortBy: Your preferred sort descriptors.
    func fetchDescriptor(sortBy: [SortDescriptor<BundleEntry>] = []) -> FetchDescriptor<BundleEntry> {
        var descriptor = FetchDescriptor<BundleEntry>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortBy
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Default sort: `sortHint` ascending. Simple, predictable, boring in the best way.
    func sortDescriptor() -> [SortDescriptor<BundleEntry>] {
        return [SortDescriptor<BundleEntry>(\.sortHint, order: .forward)]
    }

    /// AND-s all non-nil criteria into one predicate. No criteria? Everybody gets in.
    func predicate() -> Predicate<BundleEntry> {

        var conditions: [Predicate<BundleEntry>] = []

        if let bundleEntryIds, not(bundleEntryIds.isEmpty) {
            if bundleEntryIds.count == 1 {
                conditions.append(#Predicate<BundleEntry> { $0.id == bundleEntryIds.first! })
            } else {
                conditions.append(
                    #Predicate<BundleEntry> { device in
                        bundleEntryIds.contains(device.id)
                    }
                )
            }
        }

        if let channelId {
            conditions.append( #Predicate<BundleEntry> { $0.channelId == channelId })
        }

        if let channelBundleId {
            conditions.append( #Predicate<BundleEntry> { $0.channelBundle.id == channelBundleId })
        }

        if let deviceId {
            conditions.append( #Predicate<BundleEntry> { $0.channel?.deviceId == deviceId })
        }

        // if hasChannel == nil, then skip this predicate.
        // If hasChannel == true, then it means the BundleEntry is associated to a known Channel in the catalog.
        // If hasChannel == false then it means the BundleEntry channel in the catalog has been temporarily (or possibly permanently) removed.
        // Keeping the BundleEntry preserves the isFavorite state of the Channel.  Disappearing/reappearing channels will happen mostly with
        // TV Tuner channels as the user on an iPhone, iPad, Mac physically moves locations and changes network connection.
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
            return #Predicate { _ in true } // Return a predicate that always evaluates to true if no predicate conditions exist.
        } else {
            let compoundPredicate = conditions.reduce(#Predicate { _ in true }) { current, next in
                #Predicate { current.evaluate($0) && next.evaluate($0) }
            }
            return compoundPredicate
        }
    }

    //MARK: - Private API

    private var fetchLimit: Int?
    private var bundleEntryIds: [BundleEntryId]?
    private var channelId: ChannelId?
    private var channelBundleId: ChannelBundleId?
    private var deviceId: HDHomeRunDeviceId?
    private var hasChannel: Bool?
    private var showFavoritesOnly: Bool

}
