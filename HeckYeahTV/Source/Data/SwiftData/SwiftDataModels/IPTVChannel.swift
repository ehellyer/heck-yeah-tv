//
//  IPTVChannel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class IPTVChannel: JSONSerializable {
        #Index<IPTVChannel>([\.sortHint, \.id], [\.id])
        
        init(id: ChannelId,
             sortHint: String,
             title: String,
             number: String?,
             country: CountryCode?,
             categories: [CategoryId],
             languages: [LanguageCode],
             url: URL,
             logoURL: URL?,
             quality: StreamQuality,
             hasDRM: Bool,
             source: ChannelSource,
             favorite: IPTVFavorite? = nil) {
            self.id = id
            self.sortHint = sortHint
            self.title = title
            self.number = number
            self.country = country
            self.categories = categories
            self.languages = languages
            self.url = url
            self.logoURL = logoURL
            self.quality = quality
            self.hasDRM = hasDRM
            self.source = source
            self.favorite = favorite
        }
        
        @Attribute(.unique)
        var id: ChannelId
        var sortHint: String
        var title: String
        var number: String?
        var country: CountryCode? = nil
        var categories: [CategoryId] = []
        var languages: [LanguageCode] = []
        var url: URL
        var logoURL: URL?
        var quality: StreamQuality
        var hasDRM: Bool
        var source: ChannelSource
        
        // Relationship to favorite status (nullify on delete to preserve favorite when channel is deleted)
        @Relationship(deleteRule: .nullify, inverse: \IPTVFavorite.channel)
        var favorite: IPTVFavorite?
        
        // MARK: JSONSerializable Implementation
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
            case country
            case categories
            case languages
            case url
            case logoURL
            case quality
            case hasDRM
            case source
            // Note: 'favorite' relationship is not included in JSON serialization
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(sortHint, forKey: .sortHint)
            try container.encode(title, forKey: .title)
            try container.encodeIfPresent(number, forKey: .number)
            try container.encode(country, forKey: .country)
            try container.encode(categories, forKey: .categories)
            try container.encode(languages, forKey: .languages)
            try container.encode(url, forKey: .url)
            try container.encodeIfPresent(logoURL, forKey: .logoURL)
            try container.encode(quality, forKey: .quality)
            try container.encode(hasDRM, forKey: .hasDRM)
            try container.encode(source, forKey: .source)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(ChannelId.self, forKey: .id)
            self.sortHint = try container.decode(String.self, forKey: .sortHint)
            self.title = try container.decode(String.self, forKey: .title)
            self.number = try container.decodeIfPresent(String.self, forKey: .number)
            self.country = try container.decodeIfPresent(CountryCode.self, forKey: .country)
            self.categories = try container.decode([CategoryId].self, forKey: .categories)
            self.languages = try container.decode([LanguageCode].self, forKey: .languages)
            self.url = try container.decode(URL.self, forKey: .url)
            self.logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)
            self.quality = try container.decode(StreamQuality.self, forKey: .quality)
            self.hasDRM = try container.decode(Bool.self, forKey: .hasDRM)
            self.source = try container.decode(ChannelSource.self, forKey: .source)
        }
    }
}
