//
//  ChannelBundlePredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/21/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

/// Query builder for `ChannelBundle` models — keeping your bundles organized so you don't have to.
///
/// Non-nil filter criteria are AND-ed together; all must match.
struct ChannelBundlePredicate {

    /// Sets up optional filter criteria. It's just one filter for now, but it gets the job done.
    /// - Parameters:
    ///   - fetchLimit: Cap on results. Leave `nil` for the full buffet.
    ///   - bundleId: Zero in on a specific bundle by ID.
    init(fetchLimit: Int? = nil,
         bundleId: ChannelBundleId? = nil) {
        self.fetchLimit = fetchLimit
        self.bundleId = bundleId
    }

    /// Returns a fetch descriptor sorted by `name` ascending — alphabetical, like a civilized app.
    func fetchDescriptorDefaultSort() -> FetchDescriptor<ChannelBundle> {
        var descriptor = FetchDescriptor<ChannelBundle>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Returns a fetch descriptor with custom sort — go wild, we won't judge.
    /// - Parameter sortBy: Your preferred sort descriptors.
    func fetchDescriptor(sortBy: [SortDescriptor<ChannelBundle>] = []) -> FetchDescriptor<ChannelBundle> {
        var descriptor = FetchDescriptor<ChannelBundle>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortBy
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Default sort: `name` ascending. A-Z, the way the alphabet intended.
    func sortDescriptor() -> [SortDescriptor<ChannelBundle>] {
        return [SortDescriptor<ChannelBundle>(\.name, order: .forward)]
    }

    /// AND-s all non-nil criteria into one predicate. No filters? Everyone's invited.
    func predicate() -> Predicate<ChannelBundle> {

        var conditions: [Predicate<ChannelBundle>] = []

        if let bundleId {
            conditions.append( #Predicate<ChannelBundle> { $0.id == bundleId })
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
    private var bundleId: ChannelBundleId?

}
