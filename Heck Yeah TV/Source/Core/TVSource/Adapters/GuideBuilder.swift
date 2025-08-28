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
            let gc = GuideChannel(c, channelSource: .homeRunTuner)
            guideChannels[gc.id] = gc
        }
        
        let filter = [".us", ".uk"]
        let filteredStreams = streams.filter { stream in
            if let numberHint = stream.numberHint {
                return filter.firstIndex(where: { pattern in numberHint.contains(pattern) }) != nil
            }
            return false
        }
        
        for s in filteredStreams {
            let gc = GuideChannel(s, channelSource: .ipStream)
            guideChannels[gc.id] = gc
        }
        
        return guideChannels.values.sorted(by: { lhs, rhs in
            return lhs.sortHint.compare(rhs.sortHint, options: .numeric) == .orderedAscending
        })
    }
}
