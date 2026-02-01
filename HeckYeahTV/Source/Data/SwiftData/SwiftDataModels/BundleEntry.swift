//
//  BundleEntry.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class BundleEntry: JSONSerializable {
        #Index<BundleEntry>([\.sortHint, \.id], [\.id])
        
        init(id: BundleEntryId,
             channel: Channel?,
             channelBundle: ChannelBundle,
             sortHint: String,
             isFavorite: Bool = false) {
            self.id = id
            self.channel = channel
            self.channelBundle = channelBundle
            self.sortHint = sortHint
            self.isFavorite = isFavorite
        }
        
        /// Unique identifier which is a stable hash of ChannelId and ChannelBundleId
        @Attribute(.unique)
        var id: BundleEntryId
        var channel: Channel?
        var channelBundle: ChannelBundle
        var sortHint: String
        var isFavorite: Bool

        
        // MARK: - JSONSerializable Implementation (added for mock data)
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case id
            case channel
            case channelBundle
            case sortHint
            case isFavorite
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(channel, forKey: .channel)
            try container.encode(channelBundle, forKey: .channelBundle)
            try container.encode(sortHint, forKey: .sortHint)
            try container.encode(isFavorite, forKey: .isFavorite)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(BundleEntryId.self, forKey: .id)
            self.channel = try container.decode(Channel.self, forKey: .channel)
            self.channelBundle = try container.decode(ChannelBundle.self, forKey: .channelBundle)
            self.sortHint = try container.decode(String.self, forKey: .sortHint)
            self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        }
    }
}
