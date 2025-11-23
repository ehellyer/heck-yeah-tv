//
//  IPTVChannel.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/27/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

typealias ChannelId = String

@Model final class IPTVChannel: JSONSerializable {
    #Index<IPTVChannel>([\.sortHint], [\.isFavorite, \.sortHint], [\.id])

    init(id: ChannelId,
         sortHint: String,
         title: String,
         number: String?,
         url: URL,
         logoURL: URL?,
         quality: StreamQuality,
         hasDRM: Bool,
         source: ChannelSource,
         isFavorite: Bool = false) {
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
    
    // MARK: - JSONSerializable Implementation
    //
    // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
    //
    // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
    // a JSON file into the context.
    
    enum CodingKeys: String, CodingKey {
        case id
        case sortHint
        case title
        case number
        case url
        case logoURL
        case quality
        case hasDRM
        case source
        case isFavorite
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sortHint, forKey: .sortHint)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(number, forKey: .number)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(logoURL, forKey: .logoURL)
        try container.encode(quality, forKey: .quality)
        try container.encode(hasDRM, forKey: .hasDRM)
        try container.encode(source, forKey: .source)
        try container.encode(isFavorite, forKey: .isFavorite)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(ChannelId.self, forKey: .id)
        self.sortHint = try container.decode(String.self, forKey: .sortHint)
        self.title = try container.decode(String.self, forKey: .title)
        self.number = try container.decodeIfPresent(String.self, forKey: .number)
        self.url = try container.decode(URL.self, forKey: .url)
        self.logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)
        self.quality = try container.decode(StreamQuality.self, forKey: .quality)
        self.hasDRM = try container.decode(Bool.self, forKey: .hasDRM)
        self.source = try container.decode(ChannelSource.self, forKey: .source)
        self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
    }
}
