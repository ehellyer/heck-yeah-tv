//
//  HomeRunDevicePredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/22/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

/// Query builder for `HomeRunDevice` models — tracks down your HDHomeRun hardware like a bloodhound.
///
/// Non-nil filter criteria are AND-ed together; all must match.
struct HomeRunDevicePredicate {

    /// Sets up optional filter criteria. Narrow down by connectivity, enabled state, or specific device IDs.
    /// - Parameters:
    ///   - isOffline: `true` for MIA devices, `false` for the ones actually doing their job.
    ///   - isEnabled: `true` for enabled, `false` for benched. `nil` to skip this filter.
    ///   - deviceIds: Only these specific devices. Like calling roll.
    init(isOffline: Bool? = nil,
         isEnabled: Bool? = nil,
         deviceIds: [HDHomeRunDeviceId]? = nil) {
        self.isOffline = isOffline
        self.isEnabled = isEnabled
        self.deviceIds = deviceIds
    }

    /// Returns a fetch descriptor sorted by `friendlyName` ascending — the polite way to list devices.
    func fetchDescriptorDefaultSort() -> FetchDescriptor<HomeRunDevice> {
        var descriptor = FetchDescriptor<HomeRunDevice>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        return descriptor
    }

    /// Returns a fetch descriptor with custom sort — sort your devices however makes you happy.
    /// - Parameter sortBy: Your preferred sort descriptors.
    func fetchDescriptor(sortBy: [SortDescriptor<HomeRunDevice>] = []) -> FetchDescriptor<HomeRunDevice> {
        var descriptor = FetchDescriptor<HomeRunDevice>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortBy
        return descriptor
    }

    /// Default sort: `friendlyName` ascending. Names before numbers, always.
    func sortDescriptor() -> [SortDescriptor<HomeRunDevice>] {
        return [SortDescriptor<HomeRunDevice>(\.friendlyName, order: .forward)]
    }

    /// AND-s all non-nil criteria into one predicate. No filters? Every device on the network shows up.
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
