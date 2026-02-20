//
//  ChannelBundle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/20/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class ChannelBundle: JSONSerializable {
        #Index<ChannelBundle>([\.id])
        
        init(id: ChannelBundleId,
             name: String,
             channels: [BundleEntry] = []) {
            self.id = id
            self.name = name
            self.channels = channels
        }
        
        @Attribute(.unique)
        var id: ChannelBundleId
        var name: String
        
        // Relationship to Channel (nullify on delete to preserve channel when channelBundle is deleted)
        @Relationship(deleteRule: .cascade, inverse: \BundleEntry.channelBundle)
        var channels: [BundleEntry]

        
        // MARK: - JSONSerializable Implementation (added for mock data)
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
            try container.encodeIfPresent(channels, forKey: .channels)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(ChannelBundleId.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.channels = try container.decodeIfPresent([BundleEntry].self, forKey: .channels) ?? []
        }
    }
}
