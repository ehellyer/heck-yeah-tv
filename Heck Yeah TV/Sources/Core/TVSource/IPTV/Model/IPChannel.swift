//
//  IPChannel.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/channels.json](https://iptv-org.github.io/api/channels.json)
struct IPChannel: JSONSerializable {
    
    /// Unique channel Id
    var channelId: String
    
    /// Full name of the channel
    var name: String
    
    /// List of alternative channel names
    var altNames: [String]?
    
    /// Name of the network operating the channel
    var network: String?
    
    /// Name of the network operating the channel
    var owners: [String]?
    
    /// Country code from which the broadcast is transmitted ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2))
    var country: String
    
    /// Code of the subdivision (e.g., provinces or states) from which the broadcast is transmitted ([ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2))
    var subdivision: String?
    
    /// Name of the city from which the broadcast is transmitted
    var city: String?
    
    /// List of categories to which this channel belongs
    var categories: [String]?
    
    /// Indicates whether the channel broadcasts adult content
    var isNsfw: Bool
    
    /// Launch date of the channel (YYYY-MM-DD)
    var launched: String?
    
    /// Date on which the channel closed (YYYY-MM-DD)
    var closed: String?
    
    /// The ID of the channel that this channel was replaced by
    var replacedBy: String?
    
    /// Official website URL
    var website: String?
    
    private enum CodingKeys: String, CodingKey {
        case channelId = "id"
        case name
        case altNames = "alt_names"
        case network
        case owners
        case country
        case subdivision
        case city
        case categories
        case isNsfw = "is_nsfw"
        case launched
        case closed
        case replacedBy = "replaced_by"
        case website
    }
}
