//
//  ChannelBundlePredicate.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/21/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Foundation

struct ChannelBundlePredicate {
    
    /// Initialize with predicate values that will be AND together in the final predicate.
    init(bundleId: ChannelBundleId? = nil) {
        self.bundleId = bundleId
    }
    
    /// Returns a fetch descriptor with all the supplied criteria.   A sort descriptor is included on `ChannelBundle`.name ordered forward.
    func fetchDescriptor() -> FetchDescriptor<ChannelBundle> {
        var descriptor = FetchDescriptor<ChannelBundle>()
        descriptor.predicate = predicate()
        descriptor.sortBy = sortDescriptor()
        return descriptor
    }
    
    /// Returns a sort descriptor on `ChannelBundle`.name ordered forward.
    func sortDescriptor() -> [SortDescriptor<ChannelBundle>] {
        return [SortDescriptor<ChannelBundle>(\.name, order: .forward)]
    }
    
    /// Returns the predicate with the criteria values AND together.
    func predicate() -> Predicate<ChannelBundle> {
        
        var conditions: [Predicate<ChannelBundle>] = []
        
        if let bundleId {
            conditions.append( #Predicate<ChannelBundle> { $0.id == bundleId })
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
    
    private var bundleId: ChannelBundleId?
    
}
