//
//  IPGuide.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/guides.json](https://iptv-org.github.io/api/guides.json)
struct IPGuide: JSONSerializable {
    
    /// Channel Id if available (e.g., "BBCOne.uk")
    let channelId: String?
    
    /// Feed Id if available (e.g., "EastMidlandsHD")
    let feedId: String?
    
    /// Site domain name (e.g., "sky.co.uk")
    let site: String
    
    /// Unique channel Id used on the site (e.g., "bbcone")
    let siteId: String
    
    /// Channel name used on the site (e.g., "BBC One")
    let siteName: String
    
    /// Language of the guide (ISO 639-1 code) (e.g., "en")
    let lang: String
    
    private enum CodingKeys: String, CodingKey {
        case channelId = "channel"
        case feedId = "feed"
        case site
        case siteId = "site_id"
        case siteName = "site_name"
        case lang
    }
}
