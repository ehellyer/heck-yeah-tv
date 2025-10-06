//
//  IPStream.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/streams.json](https://iptv-org.github.io/api/streams.json)
struct IPStream: JSONSerializable {
    
    /// Stable hash id generated on JSON decoding. See init below.
    var id: String
    
    /// Channel Id (e.g., "France3.fr")
    let channelId: String?
    
    /// Feed Id if available; otherwise `nil` (e.g., "NordPasdeCalaisHD")
    let feedId: String?
    
    /// Stream title (e.g., "France 3 Nord Pas-de-Calais HD")
    let title: String
    
    /// Stream URL (e.g., HLS .m3u8)
    let url: URL
    
    /// The Referrer header to use for the request, if any
    let referrer: String?
    
    /// The User-Agent header to use for the request, if any
    let userAgent: String?
    
    /// Maximum stream quality (e.g., "720p"), if specified
    let quality: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel"
        case feedId = "feed"
        case title
        case url
        case referrer
        case userAgent = "user_agent"
        case quality
    }
}

extension IPStream {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.channelId = try container.decodeIfPresent(String.self, forKey: .channelId)
        self.feedId = try container.decodeIfPresent(String.self, forKey: .feedId)
        let title = try container.decode(String.self, forKey: .title)
        self.title = title
        let url = try container.decode(URL.self, forKey: .url)
        self.url = url
        self.referrer = try container.decodeIfPresent(String.self, forKey: .referrer)
        self.userAgent = try container.decodeIfPresent(String.self, forKey: .userAgent)
        self.quality = try container.decodeIfPresent(String.self, forKey: .quality)
        self.id = String.stableHashHex(url.absoluteString, title)
    }
}
