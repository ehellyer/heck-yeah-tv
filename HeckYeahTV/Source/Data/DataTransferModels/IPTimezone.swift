//
//  IPTimezone.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/timezones.json](https://iptv-org.github.io/api/timezones.json)
struct IPTimezone: JSONSerializable {
    
    /// IPTimezone Id from the tz database (e.g., "Europe/London")
    let id: String
    
    /// UTC offset for this time zone (e.g., "+00:00")
    let utcOffset: String
    
    /// List of countries included in this time zone ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2))
    let countries: [String]
}

//MARK: - JSONSerializable customization

extension IPTimezone {
    enum CodingKeys: String, CodingKey {
        case id
        case utcOffset = "utc_offset"
        case countries
    }
}
