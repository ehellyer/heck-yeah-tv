//
//  IPTVChannel.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

typealias ChannelId = String

@Model final class IPTVChannel {
    #Index<IPTVChannel>([\.sortHint], [\.isPlaying, \.sortHint], [\.isFavorite, \.sortHint])

    init(id: ChannelId,
         sortHint: String,
         title: String,
         number: String?,
         url: URL,
         logoURL: URL?,
         quality: StreamQuality,
         hasDRM: Bool,
         source: ChannelSource,
         isFavorite: Bool = false,
         isPlaying: Bool = false) {
        self.id = id
        self.sortHint = sortHint
        self.title = title
        self.number = number
        self.url = url
        self.logoURL = logoURL
        self.quality = quality
        self.hasDRM = hasDRM
        self.source = source
        self.isFavorite = isFavorite
        self.isPlaying = isPlaying
    }
    
    @Attribute(.unique)
    var id: ChannelId
    var sortHint: String
    var title: String
    var number: String?
    var url: URL
    var logoURL: URL?
    var quality: StreamQuality
    var hasDRM: Bool
    var source: ChannelSource
    var isFavorite: Bool = false
    var isPlaying: Bool = false
}
