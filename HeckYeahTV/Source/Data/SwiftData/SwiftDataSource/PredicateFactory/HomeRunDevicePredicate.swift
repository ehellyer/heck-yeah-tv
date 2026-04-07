//
//  HomeRunDevicePredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/22/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

struct HomeRunDevicePredicate {
    
    /// Initialize with predicate values that will be AND together in the final predicate.
    /// An array of device Ids are included as `AND deviceIds.contains(channel.deviceId)`.
    init(isOffline: Bool? = nil,
         isEnabled: Bool? = nil,
         deviceIds: [HDHomeRunDeviceId]? = nil) {
        self.isOffline = isOffline
        self.isEnabled = isEnabled
        self.deviceIds = deviceIds
    }
    
    /// Returns a fetch descriptor with all the supplied criteria.   A sort descriptor is included on `HomeRunDevice`.sortHint ordered forward.
    func fetchDescriptor() -> FetchDescriptor<HomeRunDevice> {
        var descriptor = FetchDescriptor<HomeRunDevice>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        return descriptor
    }
    
    /// Returns a sort descriptor on `HomeRunDevice`.sortHint ordered forward.
    func sortDescriptor() -> [SortDescriptor<HomeRunDevice>] {
        return [SortDescriptor<HomeRunDevice>(\.friendlyName, order: .forward)]
    }
    
    /// Returns the predicate with the criteria values AND together.
    /// An array of device Ids are included as `AND deviceIds.contains(HomeRunDevice.deviceId)`.
    func predicate() -> Predicate<HomeRunDevice> {
        
        var conditions: [Predicate<HomeRunDevice>] = []
        
        if let isOffline {
            conditions.append(#Predicate<HomeRunDevice> { $0.isOffline == isOffline })
        }
        
        if let isEnabled {
            conditions.append(#Predicate<HomeRunDevice> { $0.isEnabled == isEnabled })
        }
        
        if let deviceIds, not(deviceIds.isEmpty) {
            if deviceIds.count == 1 {
                conditions.append(#Predicate<HomeRunDevice> { $0.deviceId == deviceIds.first! })
            } else {
                conditions.append(
                    #Predicate<HomeRunDevice> { device in
                        deviceIds.contains(device.deviceId)
                    }
                )
            }
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
    
    private var isOffline: Bool?
    private var isEnabled: Bool?
    private var deviceIds: [HDHomeRunDeviceId]?
    
}
