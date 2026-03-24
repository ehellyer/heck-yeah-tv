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
        #Unique<ChannelBundle>([\.id])
        #Index<ChannelBundle>([\.id])
        
        init(id: ChannelBundleId,
             name: String,
             channels: [BundleEntry] = []) {
            self.id = id
            self.name = name
            self.channelEntries = channels
        }

        /// A unique identifier representing the ChannelBundle.  e.g. "4ea6d879-ffec-4325-a680-41713c672be4"
        var id: ChannelBundleId
        
        /// A name for the channel bundle provided by the user who created the bundle.  e.g. "Ed's channel bundle"
        var name: String
        
        // Relationship to Channel (cascade on delete to clean up the `BundleEntry` when channelBundle is deleted)
        @Relationship(deleteRule: .cascade, inverse: \BundleEntry.channelBundle)
        var channelEntries: [BundleEntry]
        
        // Relationship to device associations (cascade on delete to clean up join entries when bundle is deleted)
        @Relationship(deleteRule: .cascade)
        var deviceAssociations: [ChannelBundleDevice] = []

        
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
            case deviceAssociations
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(channelEntries, forKey: .channels)
            try container.encodeIfPresent(deviceAssociations, forKey: .deviceAssociations)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(ChannelBundleId.self, forKey: .id)
            self.name = try container.decode(String.self, forKey: .name)
            self.channelEntries = try container.decodeIfPresent([BundleEntry].self, forKey: .channels) ?? []
            self.deviceAssociations = try container.decodeIfPresent([ChannelBundleDevice].self, forKey: .deviceAssociations) ?? []
        }
    }
}
