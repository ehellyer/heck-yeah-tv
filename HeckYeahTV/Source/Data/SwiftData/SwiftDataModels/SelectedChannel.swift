//
//  SelectedChannel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/19/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class SelectedChannel: JSONSerializable {
        #Unique<SelectedChannel>([\.id])
        #Index<SelectedChannel>([\.dateAdded, \.channel])
        
        init(channel: Channel) {
            self.id = UUID()
            self.channel = channel
            self.dateAdded = Date()
        }
        
        // MARK: - Model Schema
        
        /// Unique identifier for the singleton instance
        private(set) var id: UUID
        
        /// The time the selected channel was added.  We are going to use this in the future to note when the user started viewing a channel.
        var dateAdded: Date
        
        // MARK: - Inverse relationships
        
        /// The currently selected channel that should be currently playing or played on app launch
        /// Delete rule nullify.  If this instance of `SelectedChannel` is deleted, the reference to `Channel` in the channel catalog is nullified and the channel remains in the catalog so that it can be selected another time.
        @Relationship(deleteRule: .nullify)
        var channel: Channel
        
        // MARK: - JSONSerializable Implementation (added for mock data)
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case id
            case channel
            case dateAdded
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(channel, forKey: .channel)
            try container.encode(dateAdded, forKey: .dateAdded)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(UUID.self, forKey: .id)
            self.channel = try container.decode(Channel.self, forKey: .channel)
            self.dateAdded = try container.decode(Date.self, forKey: .dateAdded)
        }
    }
}
