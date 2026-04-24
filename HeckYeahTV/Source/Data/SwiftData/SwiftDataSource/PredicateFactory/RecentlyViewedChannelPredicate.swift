//
//  RecentlyViewedChannelPredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/23/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

/// Query builder for `RecentlyViewedChannel` models — because your TV knows what you watched last summer.
///
/// Non-nil filter criteria are AND-ed together; all must match.
struct RecentlyViewedChannelPredicate {

    /// Sets up the fetch limit. No other filters yet — the history doesn't judge, it just remembers.
    /// - Parameter fetchLimit: Cap on results. `nil` for the full binge-watch history.
    init(fetchLimit: Int? = nil) {
        self.fetchLimit = fetchLimit
    }

    /// Returns a fetch descriptor sorted by `viewedAt` descending — most recent binge first.
    func fetchDescriptorDefaultSort() -> FetchDescriptor<RecentlyViewedChannel> {
        var descriptor = FetchDescriptor<RecentlyViewedChannel>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Returns a fetch descriptor with custom sort — rewrite history however you like.
    /// - Parameter sortBy: Your preferred sort descriptors.
    func fetchDescriptor(sortBy: [SortDescriptor<RecentlyViewedChannel>] = []) -> FetchDescriptor<RecentlyViewedChannel> {
        var descriptor = FetchDescriptor<RecentlyViewedChannel>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortBy
        descriptor.setFetchLimit(fetchLimit)
        return descriptor
    }

    /// Default sort: `viewedAt` descending. What you watched last comes first.
    func sortDescriptor() -> [SortDescriptor<RecentlyViewedChannel>] {
        return [SortDescriptor<RecentlyViewedChannel>(\.viewedAt, order: .reverse)]
    }

    /// Currently returns a wide-open predicate — all your viewing history, no secrets.
    func predicate() -> Predicate<RecentlyViewedChannel> {

        var conditions: [Predicate<RecentlyViewedChannel>]

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
