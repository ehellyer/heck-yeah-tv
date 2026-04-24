//
//  SelectedChannelPredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/24/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

/// Query builder for `SelectedChannel` models — fetches whatever's currently holding the remote.
///
/// Non-nil filter criteria are AND-ed together; all must match.
struct SelectedChannelPredicate {

    /// Sets up the fetch limit. One selection to rule them all (or a few, if you're feeling generous).
    /// - Parameter fetchLimit: Cap on results. `nil` for every selection ever made.
    init(fetchLimit: Int? = nil) {
        self.fetchLimit = fetchLimit
    }

    /// Returns a fetch descriptor sorted by `dateAdded` descending — newest pick gets top billing.
    func fetchDescriptorDefaultSort() -> FetchDescriptor<SelectedChannel> {
        var descriptor = FetchDescriptor<SelectedChannel>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Returns a fetch descriptor with custom sort — reorganize your picks as you see fit.
    /// - Parameter sortBy: Your preferred sort descriptors.
    func fetchDescriptor(sortBy: [SortDescriptor<SelectedChannel>] = []) -> FetchDescriptor<SelectedChannel> {
        var descriptor = FetchDescriptor<SelectedChannel>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortBy
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Default sort: `dateAdded` descending. Latest selection wins the spotlight.
    func sortDescriptor() -> [SortDescriptor<SelectedChannel>] {
        return [SortDescriptor<SelectedChannel>(\.dateAdded, order: .reverse)]
    }

    /// Currently returns a wide-open predicate — every selected channel makes the cut.
    func predicate() -> Predicate<SelectedChannel> {

        var conditions: [Predicate<SelectedChannel>]

        //Add conditions here as needed
        conditions = []

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

    // MARK: - Private API

    private let fetchLimit: Int?
}
