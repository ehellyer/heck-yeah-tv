//
//  IPBlocklist.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/blocklist.json](https://iptv-org.github.io/api/blocklist.json)
struct IPBlocklist: JSONSerializable {
    
    /// Channel Id (e.g., "AnimalPlanetEast.us")
    let channelId: String
    
    /// Reason for blocking (dmca or nsfw)
    let reason: String
    
    /// Link to removal request or DMCA takedown notice
    let ref: String
    
}

//MARK: - JSONSerializable customization

extension IPBlocklist {
    
    enum CodingKeys: String, CodingKey {
        case channelId = "channel"
        case reason
        case ref
    }
}
