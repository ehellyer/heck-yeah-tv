//
//  Subdivision.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/subdivisions.json](https://iptv-org.github.io/api/subdivisions.json)
struct Subdivision: JSONSerializable {
    
    /// [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the country (e.g., "CA")
    let country: String
    
    /// Subdivision name (e.g., "Ontario")
    let name: String
    
    /// [ISO 3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) code of the subdivision (e.g., "CA-ON")
    let code: String
}
