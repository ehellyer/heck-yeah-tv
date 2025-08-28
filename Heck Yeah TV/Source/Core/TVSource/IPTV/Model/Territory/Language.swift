//
//  Language.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/languages.json](https://iptv-org.github.io/api/languages.json)
struct Language: JSONSerializable {
    
    /// Language name
    var name: String
    
    /// [ISO 639-3](https://en.wikipedia.org/wiki/ISO_639-3) code of the language
    var code: String
}
