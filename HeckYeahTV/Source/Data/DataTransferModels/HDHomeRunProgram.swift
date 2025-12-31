//
//  HDHomeRunProgram.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// HDHomeRunProgram - Represents airing information for channel suitable for displaying in a Live TV guide.  Returned as an array of `HDHomeRunChannelGuide`.
///
/// e.g. [https://api.hdhomerun.com/api/guide?DeviceAuth=B3CwagB78qp9B8kjcT_UYjRL&Start=&Duration=10&Channel=](https://api.hdhomerun.com/api/guide?DeviceAuth=B3CwagB78qp9B8kjcT_UYjRL&Start=&Duration=10&Channel=) -> `[HDHomeRunChannelGuide]`
struct HDHomeRunProgram: JSONSerializable, Equatable {
    
    let startTime: Date
    let endTime: Date
    let first: Int?
    let title: String
    let episodeNumber: String?
    let episodeTitle: String?
    let synopsis: String?
    let originalAirdate: Date?
    let seriesId: String
    let imageURL: URL?
    let recordingRule: Int?
    let filter: [String]?
}

//MARK: - JSONSerializable customization

extension HDHomeRunProgram {
    
    enum CodingKeys: String, CodingKey {
        case startTime = "StartTime"
        case endTime = "EndTime"
        case first = "First"
        case title = "Title"
        case episodeNumber = "EpisodeNumber"
        case episodeTitle = "EpisodeTitle"
        case synopsis = "Synopsis"
        case originalAirdate = "OriginalAirdate"
        case seriesId = "SeriesID"
        case imageURL = "ImageURL"
        case recordingRule = "RecordingRule"
        case filter = "Filter"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let startTimeEpoch = try container.decode(Int.self, forKey: .startTime)
        self.startTime = Date(timeIntervalSince1970: TimeInterval(startTimeEpoch))
        let endTimeEpoch = try container.decode(Int.self, forKey: .endTime)
        self.endTime = Date(timeIntervalSince1970: TimeInterval(endTimeEpoch))
        self.first = try container.decodeIfPresent(Int.self, forKey: .first)
        self.title = try container.decode(String.self, forKey: .title)
        self.episodeNumber = try container.decodeIfPresent(String.self, forKey: .episodeNumber)
        self.episodeTitle = try container.decodeIfPresent(String.self, forKey: .episodeTitle)
        self.synopsis = try container.decodeIfPresent(String.self, forKey: .synopsis)
        let originalAirdateEpoch = try container.decodeIfPresent(Int.self, forKey: .originalAirdate)
        self.originalAirdate = originalAirdateEpoch.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        self.seriesId = try container.decode(String.self, forKey: .seriesId)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        self.recordingRule = try container.decodeIfPresent(Int.self, forKey: .recordingRule)
        self.filter = try container.decodeIfPresent([String].self, forKey: .filter)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(startTime.timeIntervalSince1970, forKey: .startTime)
        try container.encode(endTime.timeIntervalSince1970, forKey: .endTime)
        try container.encodeIfPresent(first, forKey: .first)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(episodeNumber, forKey: .episodeNumber)
        try container.encodeIfPresent(episodeTitle, forKey: .episodeTitle)
        try container.encodeIfPresent(synopsis, forKey: .synopsis)
        try container.encodeIfPresent(originalAirdate?.timeIntervalSince1970, forKey: .originalAirdate)
        try container.encode(seriesId, forKey: .seriesId)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(recordingRule, forKey: .recordingRule)
        try container.encodeIfPresent(filter, forKey: .filter)
    }
}
