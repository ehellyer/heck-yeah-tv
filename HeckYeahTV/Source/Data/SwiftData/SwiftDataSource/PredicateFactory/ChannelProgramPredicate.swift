//
//  ChannelProgramPredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/24/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

/// Query builder for `ChannelProgram` models — your EPG's best friend.
///
/// Non-nil filter criteria are AND-ed together; all must match.
struct ChannelProgramPredicate {

    /// Sets up optional filter criteria. Currently just `channelId` — quality over quantity.
    /// - Parameter channelId: Only programs for this channel. Leave `nil` to get the whole TV guide.
    init(channelId: ChannelId? = nil) {
        self.channelId = channelId
    }

    /// Returns a fetch descriptor sorted by `startTime` ascending — because time travel isn't supported yet.
    func fetchDescriptorDefaultSort() -> FetchDescriptor<ChannelProgram> {
        var descriptor = FetchDescriptor<ChannelProgram>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        return descriptor
    }

    /// Returns a fetch descriptor with custom sort — live dangerously.
    /// - Parameter sortBy: Your preferred sort descriptors.
    func fetchDescriptor(sortBy: [SortDescriptor<ChannelProgram>] = []) -> FetchDescriptor<ChannelProgram> {
        var descriptor = FetchDescriptor<ChannelProgram>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortBy
        return descriptor
    }

    /// Default sort: `startTime` ascending. First come, first served.
    func sortDescriptor() -> [SortDescriptor<ChannelProgram>] {
        return [SortDescriptor<ChannelProgram>(\.startTime, order: .forward)]
    }

    /// AND-s all non-nil criteria into one predicate. No channel specified? You get the whole guide.
    func predicate() -> Predicate<ChannelProgram> {

        var conditions: [Predicate<ChannelProgram>] = []

        if let channelId {
            conditions.append( #Predicate<ChannelProgram> { $0.channelId == channelId })
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
}
