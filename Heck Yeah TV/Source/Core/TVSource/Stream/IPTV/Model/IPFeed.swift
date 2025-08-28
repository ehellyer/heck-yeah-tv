//
//  IPFeed.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/feeds.json](https://iptv-org.github.io/api/feeds.json)
struct IPFeed: JSONSerializable {

    /// Channel Id (e.g., "France3.fr")
    let channelId: String

    /// Feed Id (e.g., "ParisIledeFrance")
    let feedId: String

    /// Display name (e.g., "Paris Ile-de-France")
    let name: String

    /// Alternative names (e.g., ["Paris Île-de-France"])
    let altNames: [String]

    /// True if this is the main feed for the channel
    let isMain: Bool

    /// Area codes covered (e.g., ["c/FR"])
    let broadcastArea: [String]

    /// Time zones where the feed is broadcast (e.g., ["Europe/Paris"])
    let timezones: [String]

    /// ISO 639-3 language codes (e.g., ["fra"])
    let languages: [String]

    /// Video format (e.g., "576i")
    let format: String
    
    private enum CodingKeys: String, CodingKey {
        case channelId = "channel"
        case feedId = "id"
        case name
        case altNames = "alt_names"
        case isMain = "is_main"
        case broadcastArea = "broadcast_area"
        case timezones
        case languages
        case format
    }
}
