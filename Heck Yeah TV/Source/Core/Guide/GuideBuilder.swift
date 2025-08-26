//
//  GuideBuilder.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

struct GuideBuilder {
    
    static func build(streams: [IPStream],
                      tunerChannels: [Channel]) -> [GuideChannel] {
        
        var guideChannels: [String: GuideChannel] = [:]
        
        for c in tunerChannels {
            let gc = GuideChannel(c, source: .homeRunTuner)
            guideChannels[gc.id] = gc
        }
        
        for s in streams {
            if s.channelId?.contains(".us") == true || s.channelId?.contains(".uk") == true {
                let gc = GuideChannel(s, source: .ipStream)
                // If an entry exists with same id (same URL/normalized key), keep existing (tuner)
                if guideChannels[gc.id] == nil { guideChannels[gc.id] = gc }
            }
        }
        
        return guideChannels.values.sorted(by: { lhs, rhs in
//            if let lhsNumber = lhs.number, let rhsNumber = rhs.number {
//                return lhsNumber.compare(rhsNumber, options: .numeric) == .orderedAscending
//            }
            return lhs.title.compare(rhs.title, options: .numeric) == .orderedAscending
        })
    }
}
