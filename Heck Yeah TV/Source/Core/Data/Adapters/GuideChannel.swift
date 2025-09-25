//
//  GuideChannel.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

struct GuideChannel: Identifiable, Hashable, Sendable, JSONSerializable {

    let id: String
    let sortHint: String
    let title: String
    let number: String?
    let url: URL
    let logoURL: URL?
    let quality: StreamQuality
    let hasDRM: Bool
    let source: ChannelSource
    
    init(id: String, sortHint: String, title: String, number: String? = nil, url: URL, quality: StreamQuality, hasDRM: Bool, source: ChannelSource) {
        self.id = id
        self.sortHint = sortHint
        self.title = title
        self.number = number
        self.url = url
        self.logoURL = nil
        self.quality = quality
        self.hasDRM = hasDRM
        self.source = source
    }
    
    init(_ item: Channelable, channelSource: ChannelSource) {
        
        id = item.idHint
        sortHint = item.sortHint
        title = item.titleHint
        number = item.numberHint
        url = item.urlHint
        logoURL = nil
        quality = item.qualityHint
        hasDRM = item.hasDRMHint
        source = channelSource
    }
    
    static func mockGuideChannels() -> [GuideChannel] {
        return [
            GuideChannel(id: "1",
                         sortHint: "A",
                         title: "ABC News",
                         number: "abceast.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.uhd8k,
                         hasDRM: false,
                         source: ChannelSource.ipStream),
            GuideChannel(id: "2",
                         sortHint: "B",
                         title: "Sports Center",
                         number: "sportschannel.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.sd,
                         hasDRM: false,
                         source: ChannelSource.ipStream),
            GuideChannel(id: "3",
                         sortHint: "C",
                         title: "Movie Channel",
                         number: "moveanchannel.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.fhd,
                         hasDRM: false,
                         source: ChannelSource.ipStream),
            GuideChannel(id: "4",
                         sortHint: "D",
                         title: "Discovery",
                         number: "nationalgeographic.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.uhd4k,
                         hasDRM: false,
                         source: ChannelSource.ipStream),
            GuideChannel(id: "5",
                         sortHint: "E",
                         title: "Top Gear",
                         number: "nationalgeographic.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.uhd4k,
                         hasDRM: false,
                         source: ChannelSource.ipStream),
            GuideChannel(id: "6",
                         sortHint: "F",
                         title: "Planet Earth",
                         number: "nationalgeographic.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.uhd4k,
                         hasDRM: false,
                         source: ChannelSource.ipStream)
        ]
    }
}
