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
    
    /// Unique channel Id of the source data. (e.g., "France3.fr")
    let channelId: String
    
    /// Full name of the channel
    let name: String
    
    /// List of alternative channel names
    let altNames: [String]?
    
    /// Name of the network operating the channel
    let network: String?
    
    /// Name of the network operating the channel
    let owners: [String]?
    
    /// Country code from which the broadcast is transmitted ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2))
    let country: String
    
    /// Code of the subdivision (e.g., provinces or states) from which the broadcast is transmitted ([ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2))
    let subdivision: String?
    
    /// Name of the city from which the broadcast is transmitted
    let city: String?
    
    /// List of categories to which this channel belongs
    let categories: [String]?
    
    /// Indicates whether the channel broadcasts adult content
    let isNsfw: Bool
    
    /// Launch date of the channel (YYYY-MM-DD)
    let launched: String?
    
    /// Date on which the channel closed (YYYY-MM-DD)
    let closed: String?
    
    /// The ID of the channel that this channel was replaced by
    let replacedBy: String?
    
    /// Official website URL
    let website: String?
    
}

//MARK: - JSONSerializable customization

extension IPChannel {
    
    enum CodingKeys: String, CodingKey {
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
