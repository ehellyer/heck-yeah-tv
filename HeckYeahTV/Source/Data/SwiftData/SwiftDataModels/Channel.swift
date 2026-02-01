//
//  Channel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/30/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

extension SchemaV1 {
    
    /// Represents an instance from the master list of all possible channels.
    @Model final class Channel: JSONSerializable {
        #Index<Channel>([\.sortHint, \.id], [\.id])
        
        init(id: ChannelId,
             guideId: String?,
             sortHint: String,
             title: String,
             number: String?,
             country: CountryCodeId?,
             categories: [ProgramCategory],
             languages: [LanguageCodeId],
             url: URL,
             logoURL: URL?,
             quality: StreamQuality,
             hasDRM: Bool,
             source: ChannelSourceId,
             deviceId: HDHomeRunDeviceId?) {
            self.id = id
            self.guideId = guideId
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
            self.deviceId = deviceId
        }
        
        @Attribute(.unique)
        var id: ChannelId
        
        /// The unique identifier to link guide information from the channels originating source.
        var guideId: String?
        
        var sortHint: String
        var title: String
        var number: String?
        var country: CountryCodeId?
        
        // Many-to-many relationship with categories
        @Relationship(deleteRule: .nullify)
        var categories: [ProgramCategory] = []
        
        var languages: [LanguageCodeId] = []
        var url: URL
        var logoURL: URL?
        var quality: StreamQuality
        var hasDRM: Bool
        var source: ChannelSourceId
        var deviceId: HDHomeRunDeviceId?
        
        
        // MARK: - JSONSerializable Implementation (added for mock data)
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case id
            case guideId
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
            case deviceId
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(guideId, forKey: .guideId)
            try container.encode(sortHint, forKey: .sortHint)
            try container.encode(title, forKey: .title)
            try container.encodeIfPresent(number, forKey: .number)
            try container.encodeIfPresent(country, forKey: .country)
            try container.encode(categories, forKey: .categories)
            try container.encode(languages, forKey: .languages)
            try container.encode(url, forKey: .url)
            try container.encodeIfPresent(logoURL, forKey: .logoURL)
            try container.encode(quality, forKey: .quality)
            try container.encode(hasDRM, forKey: .hasDRM)
            try container.encode(source, forKey: .source)
            try container.encodeIfPresent(deviceId, forKey: .deviceId)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(ChannelId.self, forKey: .id)
            self.guideId = try container.decodeIfPresent(String.self, forKey: .guideId)
            self.sortHint = try container.decode(String.self, forKey: .sortHint)
            self.title = try container.decode(String.self, forKey: .title)
            self.number = try container.decodeIfPresent(String.self, forKey: .number)
            self.country = try container.decodeIfPresent(CountryCodeId.self, forKey: .country)
            self.categories = try container.decodeIfPresent([ProgramCategory].self, forKey: .categories) ?? []
            self.languages = try container.decode([LanguageCodeId].self, forKey: .languages)
            self.url = try container.decode(URL.self, forKey: .url)
            self.logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)
            self.quality = try container.decode(StreamQuality.self, forKey: .quality)
            self.hasDRM = try container.decode(Bool.self, forKey: .hasDRM)
            self.source = try container.decode(ChannelSourceId.self, forKey: .source)
            self.deviceId = try container.decodeIfPresent(HDHomeRunDeviceId.self, forKey: .deviceId)
        }
    }
}
