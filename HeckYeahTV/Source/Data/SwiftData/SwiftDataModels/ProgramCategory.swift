//
//  IPCategory.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/1/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class ProgramCategory: JSONSerializable {
        #Index<ProgramCategory>([\.categoryId])
        
        init(categoryId: String,
             name: String,
             categoryDescription: String) {
            
            self.categoryId = categoryId
            self.name = name
            self.categoryDescription = categoryDescription
        }
        
        @Attribute(.unique)
        var categoryId: CategoryId
        
        /// Name of the category
        var name: String
        
        /// Short description of the category
        var categoryDescription: String
        
        /// Channels that belong to this category (many-to-many relationship)
        @Relationship(deleteRule: .nullify, inverse: \Channel.categories)
        var channels: [Channel]? = []
        
        // MARK: - JSONSerializable Implementation (added for mock data)
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case categoryId
            case name
            case categoryDescription
            // Note: 'channels' relationship is not included in JSON serialization
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(categoryId, forKey: .categoryId)
            try container.encode(name, forKey: .name)
            try container.encode(categoryDescription, forKey: .categoryDescription)
        }
        
        init(from decoder: Decoder) throws {
            do {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.categoryId = try container.decode(CategoryId.self, forKey: .categoryId)
                self.name = try container.decode(String.self, forKey: .name)
                self.categoryDescription = try container.decode(String.self, forKey: .categoryDescription)
            } catch {
                logError("Unable to decode ProgramCategory from JSON data error: \(error)")
                throw error
            }
        }
    }
}
