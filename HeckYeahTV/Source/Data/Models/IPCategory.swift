//
//  IPCategory.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/categories.json](https://iptv-org.github.io/api/categories.json)
struct IPCategory: JSONSerializable {
    
    /// Category Id
    var categoryId: CategoryId
    
    /// Name of the category
    var name: String
    
    /// Short description of the category
    var description: String
    
    private enum CodingKeys: String, CodingKey {
        case categoryId = "id"
        case name
        case description
    }
}
