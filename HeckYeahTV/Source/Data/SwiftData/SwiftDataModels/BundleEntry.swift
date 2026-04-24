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
    
    /// A `BundleEntry` represents a channel added to a channel bundle.
    @Model final class BundleEntry: JSONSerializable {
        #Unique<BundleEntry>([\.id])
        #Index<BundleEntry>([\.sortHint, \.id], [\.id])
        
        init(channel: Channel,
             channelBundle: ChannelBundle,
             sortHint: String,
             isFavorite: Bool = false) {
            
            let bundleEntryId = BundleEntry.newBundleEntryId(channelBundleId: channelBundle.id, channelId: channel.id)
            
            self.id = bundleEntryId
            self.channel = channel
            self.channelId = channel.id
            self.channelBundle = channelBundle
            self.sortHint = sortHint
            self.isFavorite = isFavorite
        }
        
        /// Unique identifier for a `BundleEntry`.  Another unique combination would be the compound key on ChannelBundle.id && Channel.id.
        var id: BundleEntryId
        
        /// The `Channel` this `BundleEntry` represents in the `ChannelBundle`.
        @Relationship(deleteRule: .nullify)
        var channel: Channel?
        
        /// The unique identifier of the `Channel` this `BundleEntry` represents in the `ChannelBundle`.
        ///
        /// This value is persisted when the `Channel` is removed from the channel catalog.
        /// It is used to associate the orphaned `BundleEntry` to the original `Channel` when the channel is added back to the channel catalog.
        var channelId: ChannelId
        
        /// The `ChannelBundle` this `BundleEntry` is a member of.
        @Relationship(deleteRule: .nullify)
        var channelBundle: ChannelBundle
        
        /// A sort key used for display in a guide.
        var sortHint: String
        
        /// A flag that indicates this `BundleEntry` instance represents a favorite channel in the `ChannelBundle`.
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
            case channelId
            case channelBundle
            case sortHint
            case isFavorite
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(channel, forKey: .channel)
            try container.encode(channelId, forKey: .channelId)
            try container.encode(channelBundle, forKey: .channelBundle)
            try container.encode(sortHint, forKey: .sortHint)
            try container.encode(isFavorite, forKey: .isFavorite)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = try container.decode(BundleEntryId.self, forKey: .id)
            self.channel = try container.decodeIfPresent(Channel.self, forKey: .channel)
            self.channelId = try container.decode(ChannelId.self, forKey: .channelId)
            self.channelBundle = try container.decode(ChannelBundle.self, forKey: .channelBundle)
            self.sortHint = try container.decode(String.self, forKey: .sortHint)
            self.isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        }
    }
}
