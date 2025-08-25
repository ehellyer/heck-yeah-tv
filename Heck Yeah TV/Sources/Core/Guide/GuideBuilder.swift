//
//  GuideBuilder.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
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
            let gc = GuideChannel(s, source: .ipStream)
            // If an entry exists with same id (same URL/normalized key), keep existing (tuner)
            if guideChannels[gc.id] == nil { guideChannels[gc.id] = gc }
        }
        
        return guideChannels.values.sorted(by: { lhs, rhs in
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        })
    }
}
