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

    let id: ChannelId
    let sortHint: String
    let title: String
    let number: String?
    let url: URL
    let logoURL: URL?
    let quality: StreamQuality
    let hasDRM: Bool
    let source: ChannelSource
    var isFavorite: Bool = false
    var isPlaying: Bool = false
    
    init(id: ChannelId,
         sortHint: String,
         title: String,
         number: String? = nil,
         url: URL,
         quality: StreamQuality,
         hasDRM: Bool,
         source: ChannelSource,
         isFavorite: Bool,
         isPlaying: Bool) {
        self.id = id
        self.sortHint = sortHint
        self.title = title
        self.number = number
        self.url = url
        self.logoURL = nil
        self.quality = quality
        self.hasDRM = hasDRM
        self.source = source
        self.isFavorite = isFavorite
        self.isPlaying = isPlaying
    }
    
    init(_ item: Channelable, channelSource: ChannelSource, isFavorite: Bool, isPlaying: Bool) {
        self.id = item.idHint
        self.sortHint = item.sortHint
        self.title = item.titleHint
        self.number = item.numberHint
        self.url = item.urlHint
        self.logoURL = nil
        self.quality = item.qualityHint
        self.hasDRM = item.hasDRMHint
        self.source = channelSource
        self.isFavorite = isFavorite
        self.isPlaying = isPlaying
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
                         source: ChannelSource.ipStream,
                         isFavorite: false,
                         isPlaying: false),
            GuideChannel(id: "2",
                         sortHint: "B",
                         title: "Sports Center",
                         number: "sportschannel.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.sd,
                         hasDRM: false,
                         source: ChannelSource.ipStream,
                         isFavorite: false,
                         isPlaying: false),
            GuideChannel(id: "3",
                         sortHint: "C",
                         title: "Movie Channel",
                         number: "moveanchannel.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.fhd,
                         hasDRM: false,
                         source: ChannelSource.ipStream,
                         isFavorite: false,
                         isPlaying: false),
            GuideChannel(id: "4",
                         sortHint: "D",
                         title: "Discovery",
                         number: "nationalgeographic.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.uhd4k,
                         hasDRM: false,
                         source: ChannelSource.ipStream,
                         isFavorite: false,
                         isPlaying: false),
            GuideChannel(id: "5",
                         sortHint: "E",
                         title: "Top Gear",
                         number: "nationalgeographic.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.uhd4k,
                         hasDRM: false,
                         source: ChannelSource.ipStream,
                         isFavorite: false,
                         isPlaying: false),
            GuideChannel(id: "6",
                         sortHint: "F",
                         title: "Planet Earth",
                         number: "nationalgeographic.us",
                         url: URL(string: "https://abc.com")!,
                         quality: StreamQuality.uhd4k,
                         hasDRM: false,
                         source: ChannelSource.ipStream,
                         isFavorite: false,
                         isPlaying: false)
        ]
    }
}
