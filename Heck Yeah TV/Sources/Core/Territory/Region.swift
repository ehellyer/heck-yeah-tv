//
//  Region.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/regions.json](https://iptv-org.github.io/api/regions.json)
struct Region: JSONSerializable {
    
    /// Code of the region (e.g., "MAGHREB")
    let code: String
    
    /// Full name of the region (e.g., "Maghreb")
    let name: String
    
    /// List of countries in the region ([ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2))
    let countries: [String]
}
