//
//  ChannelPredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/21/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

/// Query builder for `Channel` models — your personal TV guide bouncer.
///
/// Non-nil filter criteria are AND-ed together; all must match.
struct ChannelPredicate {

    /// Sets up optional filter criteria. Mix and match to your heart's content.
    /// - Parameters:
    ///   - fetchLimit: Cap on results. `nil` means bring 'em all.
    ///   - channelId: Find one specific channel by ID.
    ///   - searchTerm: Case-insensitive title search — typos not forgiven, though.
    ///   - countryCode: Filter by country code, for the geographically decisive.
    ///   - categoryId: Stick to channels in a specific category.
    ///   - deviceIds: Only channels from these devices make the cut.
    ///   - deviceChannelsOnly: When `true`, boots all IPTV channels and keeps only HDHomeRun hardware channels.
    init(fetchLimit: Int? = nil,
         channelId: ChannelId? = nil,
         searchTerm: String? = nil,
         countryCode: CountryCodeId? = nil,
         categoryId: CategoryId? = nil,
         deviceIds: [HDHomeRunDeviceId]? = nil,
         deviceChannelsOnly: Bool = false) {
        self.fetchLimit = fetchLimit
        self.channelId = channelId
        self.searchTerm = searchTerm
        self.countryCode = countryCode
        self.categoryId = categoryId
        self.deviceIds = deviceIds
        self.deviceChannelsOnly = deviceChannelsOnly
    }

    /// Returns a fetch descriptor sorted by `sortHint` ascending — channels in their natural habitat.
    func fetchDescriptorDefaultSort() -> FetchDescriptor<Channel> {
        var descriptor = FetchDescriptor<Channel>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Returns a fetch descriptor with custom sort — dealer's choice.
    /// - Parameter sortBy: Your preferred sort descriptors.
    func fetchDescriptor(sortBy: [SortDescriptor<Channel>] = []) -> FetchDescriptor<Channel> {
        var descriptor = FetchDescriptor<Channel>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortBy
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Default sort: `sortHint` ascending. The channel lineup as nature intended.
    func sortDescriptor() -> [SortDescriptor<Channel>] {
        return [SortDescriptor<Channel>(\.sortHint, order: .forward)]
    }

    /// AND-s all non-nil criteria into one predicate. No criteria? The velvet rope comes down and everybody gets in.
    func predicate() -> Predicate<Channel> {

        var conditions: [Predicate<Channel>] = []

        if let channelId {
            conditions.append( #Predicate<Channel> { $0.id == channelId })
        }

        if let searchTerm, searchTerm.count > 0 {
            conditions.append( #Predicate<Channel> { $0.title.localizedStandardContains(searchTerm) })
        }

        if let countryCode {
            conditions.append( #Predicate<Channel> { $0.country == countryCode })
        }

        if let categoryId {
            conditions.append( #Predicate<Channel> { channel in
                channel.categories.contains(where: { $0.categoryId == categoryId })
            })
        }

        if let deviceIds, not(deviceIds.isEmpty) {
            if deviceIds.count == 1 {
                conditions.append(#Predicate<Channel> { $0.deviceId == deviceIds.first! })
            } else {
                conditions.append(
                    #Predicate<Channel> { channel in
                        deviceIds.contains(channel.deviceId)
                    }
                )
            }
        }

        // Special case to match channels for any HDHomeRunDevice.  It excludes all IPTV channels.
        if deviceChannelsOnly {
            let iptvDeviceId = IPTVImporter.iptvDeviceId
            conditions.append(#Predicate<Channel> { $0.deviceId != iptvDeviceId })
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

    private let fetchLimit: Int?
    private var channelId: ChannelId?
    private var searchTerm: String?
    private var countryCode: CountryCodeId?
    private var categoryId: CategoryId?
    private var deviceIds: [HDHomeRunDeviceId]?
    private var deviceChannelsOnly: Bool

}
