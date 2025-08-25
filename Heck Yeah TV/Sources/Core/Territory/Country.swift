//
//  Country.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/countries.json](https://iptv-org.github.io/api/countries.json)
struct Country: JSONSerializable {
    
    /// Name of the country
    var name: String
    
    /// [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) code of the country
    var code: String
    
    /// List of official languages of the country ([ISO 639-3](https://en.wikipedia.org/wiki/ISO_639-3) code)
    var languages: [String]
    
    /// Country flag emoji
    var flag: String
}
