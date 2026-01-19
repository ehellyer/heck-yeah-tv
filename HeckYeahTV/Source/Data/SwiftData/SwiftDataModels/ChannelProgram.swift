//
//  ChannelProgram.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class ChannelProgram: JSONSerializable {
        #Index<ChannelProgram>([\.id], [\.channelId, \.startTime])
        
        init(id: ChannelProgramId,
             channelId: ChannelId,
             startTime: Date,
             endTime: Date,
             first: Int?,
             title: String,
             episodeNumber: String?,
             episodeTitle: String?,
             synopsis: String?,
             originalAirDate: Date?,
             programImageURL: URL?,
             recordingRule: Int?,
             filter: [String]
             ) {
            self.id = id
            self.channelId = channelId
            self.startTime = startTime
            self.endTime = endTime
            self.first = first
            self.title = title
            self.episodeNumber = episodeNumber
            self.episodeTitle = episodeTitle
            self.synopsis = synopsis
            self.originalAirDate = originalAirDate
            self.programImageURL = programImageURL
            self.recordingRule = recordingRule
            self.filter = filter
            
        }
        
        
        #Unique<ChannelProgram>([\.id])
        var id: ChannelProgramId        // Stable hash on channelId and startTime.  This is done in theHomeRunImporter where the init is first called.  It is the only place where all the mapping can be done on dependent fetches.
        var channelId: ChannelId
        var startTime: Date
        var endTime: Date
        var first: Int?
        var title: String
        var episodeNumber: String?
        var episodeTitle: String?
        var synopsis: String?
        var originalAirDate: Date?
        var programImageURL: URL?
        var recordingRule: Int?
        var filter: [String]
        
        
        // MARK: JSONSerializable Implementation
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case id
            case channelId
            case startTime
            case endTime
            case first
            case title
            case episodeNumber
            case episodeTitle
            case synopsis
            case originalAirDate
            case programImageURL
            case recordingRule
            case filter
        }
        
        func encode(to encoder: Encoder) throws {
            
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(channelId, forKey: .channelId)
            try container.encode(startTime, forKey: .startTime)
            try container.encode(endTime, forKey: .endTime)
            try container.encodeIfPresent(first, forKey: .first)
            try container.encode(title, forKey: .title)
            try container.encodeIfPresent(episodeNumber, forKey: .episodeNumber)
            try container.encodeIfPresent(episodeTitle, forKey: .episodeTitle)
            try container.encodeIfPresent(synopsis, forKey: .synopsis)
            try container.encodeIfPresent(originalAirDate, forKey: .originalAirDate)
            try container.encodeIfPresent(programImageURL, forKey: .programImageURL)
            try container.encodeIfPresent(recordingRule, forKey: .recordingRule)
            try container.encode(filter, forKey: .filter)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(ChannelProgramId.self, forKey: .id)
            self.channelId = try container.decode(ChannelId.self, forKey: .channelId)
            self.startTime = try container.decode(Date.self, forKey: .startTime)
            self.endTime = try container.decode(Date.self, forKey: .endTime)
            self.first = try container.decodeIfPresent(Int.self, forKey: .first)
            self.title = try container.decode(String.self, forKey: .title)
            self.episodeNumber = try container.decodeIfPresent(String.self, forKey: .episodeNumber)
            self.episodeTitle = try container.decodeIfPresent(String.self, forKey: .episodeTitle)
            self.synopsis = try container.decodeIfPresent(String.self, forKey: .synopsis)
            self.originalAirDate = try container.decodeIfPresent(Date.self, forKey: .originalAirDate)
            self.programImageURL = try container.decodeIfPresent(URL.self, forKey: .programImageURL)
            self.recordingRule = try container.decodeIfPresent(Int.self, forKey: .recordingRule)
            self.filter = try container.decode([String].self, forKey: .filter)
        }
    }
}
