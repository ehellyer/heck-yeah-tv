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
        case channelId = "channel"
        case feedId = "feed"
        case title
        case url
        case referrer
        case userAgent = "user_agent"
        case quality
    }
}
