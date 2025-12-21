//
//  Guide.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/20/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class Guide: JSONSerializable {
        #Index<Guide>([\.id])
        
        init(id: GuideId,
             name: String,
             channels: [IPTVChannel]) {
            self.id = id
            self.name = name
            self.channels = channels
        }
        
        @Attribute(.unique)
        var id: GuideId
        var name: String
        
        // Many-to-many relationship with channels (nullify on delete to preserve channels when guide is deleted)
        @Relationship(deleteRule: .nullify, inverse: \IPTVChannel.guides)
        var channels: [IPTVChannel] = []
        
        // MARK: JSONSerializable Implementation
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case channels
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(channels, forKey: .channels)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(GuideId.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.channels = try container.decode([IPTVChannel] .self, forKey: .channels)
        }
    }
}
