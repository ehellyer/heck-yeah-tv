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
    let categoryId: CategoryId
    
    /// Name of the category
    let name: String
    
    /// Short description of the category
    let description: String
    
}

//MARK: - JSONSerializable customization

extension IPCategory {
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "id"
        case name
        case description
    }
}
