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
/// e.g. [http://192.168.78.220/lineup.json](http://192.168.78.220/lineup.json) -> `[HDHomeRunChannel]`
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
    
    /// Used only for identifying the deviceId this channel is served from.
    let deviceId: HDHomeRunDeviceId
    
    /// Bool to flag if the channel has digital rights management enabled.
    let hasDRM: Bool
    
    /// Bool to flag if the channel is a HD channel or not.
    let isHD: Bool
    
    /// URL for the source stream of the channel.
    let url: URL
    
    /// URL for the channel logo.  Set after object has been decoded.  The logo URL comes from a separate route.
    var logoURL: URL?
}

//MARK: - JSONSerializable customization

extension HDHomeRunChannel {
    
    enum CodingKeys: String, CodingKey {
        case id
        case guideNumber = "GuideNumber"
        case guideName = "GuideName"
        case videoCodec = "VideoCodec"
        case audioCodec = "AudioCodec"
        case deviceId
        case hasDRM = "DRM"
        case isHD = "HD"
        case url = "URL"
        case logoURL
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let guideNumber = try container.decode(String.self, forKey: .guideNumber)
        let url = try container.decode(URL.self, forKey: .url)

        // Stable hash identifier generated over `url` and `guideNumber`.
        self.id = String.stableHashHex(url.absoluteString, guideNumber)
        self.guideNumber = guideNumber
        self.guideName = try container.decode(String.self, forKey: .guideName)
        self.videoCodec = try container.decodeIfPresent(String.self, forKey: .videoCodec)
        self.audioCodec = try container.decodeIfPresent(String.self, forKey: .audioCodec)
        self.hasDRM = (try container.decodeIfPresent(Int.self, forKey: .hasDRM)) ?? 0 == 1
        self.isHD = (try container.decodeIfPresent(Int.self, forKey: .isHD)) ?? 0 == 1
        self.url = url
        self.logoURL = try container.decodeIfPresent(URL.self, forKey: .logoURL)
        
        
        //Special case - The deviceId is passed in the decoders userInfo dictionary prior to calling the decode using the JSONSerializable initializer function initialize(jsonData: Data?, codingUserInfo: [CodingUserInfoKey : any Sendable]).
        guard let deviceId = decoder.userInfo[CodingUserInfoKey.homeRunDeviceIdKey] as? HDHomeRunDeviceId else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Missing or invalid deviceId data in decoder.userInfo"
                )
            )
        }
        self.deviceId = deviceId
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(guideNumber, forKey: .guideNumber)
        try container.encode(guideName, forKey: .guideName)
        try container.encodeIfPresent(videoCodec, forKey: .videoCodec)
        try container.encodeIfPresent(audioCodec, forKey: .audioCodec)
        try container.encode(deviceId, forKey: .deviceId)
        if hasDRM { try container.encode(1, forKey: .hasDRM) }
        if isHD { try container.encode(1, forKey: .isHD) }
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(logoURL, forKey: .logoURL)
    }
}

extension CodingUserInfoKey {
    static let homeRunDeviceIdKey: CodingUserInfoKey = CodingUserInfoKey(rawValue: "homeRunDeviceIdKey")!
}
