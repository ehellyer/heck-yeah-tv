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
                      tunerChannels: [HDHomeRunChannel],
                      previouslyDiscovered: [GuideChannel]) -> [GuideChannel] {
        
        var guideChannels: [String: GuideChannel] = [:]
        let favorites: [String] = previouslyDiscovered.filter({$0.isFavorite}).map({$0.id})
        let playingId: String = previouslyDiscovered.first(where: {$0.isPlaying})?.id ?? ""
        
        for c in tunerChannels {
            let gc = GuideChannel(c, channelSource: .homeRunTuner, isFavorite: favorites.contains(c.idHint), isPlaying: c.idHint == playingId)
            guideChannels[gc.id] = gc
        }
        
        //TODO: Remove this trivial filter, it is for dev only to keep the channel numbers relatively small.
        let filter = [".us", ".uk"]
        let filteredStreams = streams.filter { stream in
            if let numberHint = stream.numberHint {
                return filter.firstIndex(where: { pattern in numberHint.contains(pattern) }) != nil
            }
            return false
        }
        
        for s in filteredStreams {
            let gc = GuideChannel(s, channelSource: .ipStream, isFavorite: favorites.contains(s.idHint), isPlaying: s.idHint == playingId)
            guideChannels[gc.id] = gc
        }
        
        let sortedChannels = guideChannels.values.sorted(by: { lhs, rhs in
            return lhs.sortHint.compare(rhs.sortHint, options: .numeric) == .orderedAscending
        })
        return sortedChannels
    }
}
