//
//  HDHomeRunChannel.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// HDHomeRunChannel - Returned as an array when asking for the tuners channel list.
///
/// e.g. [http://192.168.78.220/lineup.json](http://192.168.78.220/lineup.json) -> [Channel]
struct HDHomeRunChannel: JSONSerializable, Equatable {
    
    /// Stable hash id generated on JSON decoding. See init below.
    let id: String
    
    /// The guide number assigned by HDHomeRun
    let guideNumber: String
    
    /// The channel name.
    let guideName: String
    
    /// The video codec in use for the channel.
    let videoCodec: String?
    
    /// The audio codec in use for the channel.
    let audioCodec: String?
    
    /// Bool to flag if the channel has digital rights management enabled.
    let hasDRM: Bool
    
    /// Bool to flag if the channel is a HD channel or not.
    let isHD: Bool
    
    /// URL for the source stream of the channel.
    let url: URL
}

extension HDHomeRunChannel {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let guideNumber = try container.decode(String.self, forKey: .guideNumber)
        self.guideNumber = guideNumber
        self.guideName = try container.decode(String.self, forKey: .guideName)
        self.videoCodec = try container.decodeIfPresent(String.self, forKey: .videoCodec)
        self.audioCodec = try container.decodeIfPresent(String.self, forKey: .audioCodec)
        self.hasDRM = (try container.decodeIfPresent(Int.self, forKey: .hasDRM)) ?? 0 == 1
        self.isHD = (try container.decodeIfPresent(Int.self, forKey: .isHD)) ?? 0 == 1
        let url = try container.decode(URL.self, forKey: .url)
        self.url = url
        self.id = String.stableHashHex(url.absoluteString, guideNumber)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(guideNumber, forKey: .guideNumber)
        try container.encode(guideName, forKey: .guideName)
        try container.encode(videoCodec, forKey: .videoCodec)
        try container.encode(audioCodec, forKey: .audioCodec)
        if hasDRM { try container.encode(1, forKey: .hasDRM) }
        if isHD { try container.encode(1, forKey: .isHD) }
        try container.encode(url, forKey: .url)
        try container.encode(id, forKey: .id)
    }
}

extension HDHomeRunChannel {
    
    enum CodingKeys: String, CodingKey {
        case id
        case guideNumber = "GuideNumber"
        case guideName = "GuideName"
        case videoCodec = "VideoCodec"
        case audioCodec = "AudioCodec"
        case hasDRM = "DRM"
        case isHD = "HD"
        case url = "URL"
    }
}
