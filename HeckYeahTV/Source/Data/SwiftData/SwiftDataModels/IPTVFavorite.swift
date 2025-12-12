//
//  IPTVFavorite.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/8/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData
import Hellfire

extension SchemaV1 {

    @Model final class IPTVFavorite: JSONSerializable {
        #Index<IPTVFavorite>([\.isFavorite, \.id], [\.id])

        init(id: ChannelId,
             isFavorite: Bool,
             channel: IPTVChannel? = nil) {
            self.id = id
            self.isFavorite = isFavorite
            self.channel = channel
        }
        
        /// The stable hash that is the unique identifier of the channel that has been added to favorites.
        @Attribute(.unique)
        var id: ChannelId

        /// Returns the current favorite state of the channel.
        var isFavorite: Bool
        
        /// Optional relationship back to the channel (if it exists)
        var channel: IPTVChannel?
        
        // MARK: - JSONSerializable Implementation
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case id
            case isFavorite
            // Note: 'channel' relationship is not included in JSON serialization
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(isFavorite, forKey: .isFavorite)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(ChannelId.self, forKey: .id)
            self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        }
    }
}
