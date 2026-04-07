//
//  ChannelPredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/21/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

struct ChannelPredicate {
    
    /// Initialize with predicate values that will be AND together in the final predicate.
    /// An array of device Ids are included as `AND deviceIds.contains(channel.deviceId)`.
    init(channelId: ChannelId? = nil,
         searchTerm: String? = nil,
         countryCode: CountryCodeId? = nil,
         categoryId: CategoryId? = nil,
         deviceIds: [HDHomeRunDeviceId]? = nil,
         deviceChannelsOnly: Bool = false) {
        self.channelId = channelId
        self.searchTerm = searchTerm
        self.countryCode = countryCode
        self.categoryId = categoryId
        self.deviceIds = deviceIds
        self.deviceChannelsOnly = deviceChannelsOnly
    }
    
    /// Returns a fetch descriptor with all the supplied predicates.  No sort descriptor is included as this is intended for a fetchCount() operation.
    func fetchDescriptorNoSort() -> FetchDescriptor<Channel> {
        var descriptor = FetchDescriptor<Channel>()
        descriptor.predicate = predicate()
        return descriptor
    }
    
    /// Returns a fetch descriptor with all the supplied criteria.   A sort descriptor is included on `Channel`.sortHint ordered forward.
    func fetchDescriptor() -> FetchDescriptor<Channel> {
        var descriptor = FetchDescriptor<Channel>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        return descriptor
    }
    
    /// Returns a sort descriptor on `Channel`.sortHint ordered forward.
    func sortDescriptor() -> [SortDescriptor<Channel>] {
        return [SortDescriptor<Channel>(\.sortHint, order: .forward)]
    }
    
    /// Returns the predicate with the criteria values AND together.
    /// An array of device Ids are included as `AND deviceIds.contains(channel.deviceId)`.
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
    
    private var channelId: ChannelId?
    private var searchTerm: String?
    private var countryCode: CountryCodeId?
    private var categoryId: CategoryId?
    private var deviceIds: [HDHomeRunDeviceId]?
    private var deviceChannelsOnly: Bool
    
}
