//
//  RecentlyViewedChannel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/12/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Hellfire

extension SchemaV1 {
    
    @Model final class RecentlyViewedChannel: JSONSerializable {
        #Unique<RecentlyViewedChannel>([\.channelId])
        #Index<RecentlyViewedChannel>([\.viewedAt, \.channelId])
        
        init(channel: Channel,
             viewedAt: Date = Date()) {
            self.channelId = channel.id
            self.channel = channel
            self.viewedAt = viewedAt
        }
        
        /// The unique identifier for the Channel.  This is used by SwiftData to either insert or update an instance of `RecentlyViewedChannel`
        var channelId: ChannelId
        
        /// The timestamp when this channel was viewed
        var viewedAt: Date
        
        /// Relationship to the Channel that was viewed
        @Relationship(deleteRule: .noAction)
        var channel: Channel
        
        // MARK: - JSONSerializable Implementation (added for mock data)
        //
        // JSONSerializable implementation not automatically synthesized due to a conflict with SwiftData @Model automatic synthesis of certain behaviors.
        //
        // JSONSerializable has been added to support mock data used in previews.  Where we create an in-memory SwiftData context and load mock data from
        // a JSON file into the context.
        
        enum CodingKeys: String, CodingKey {
            case channelId
            case viewedAt
            case channel
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(channelId, forKey: .channelId)
            try container.encode(viewedAt, forKey: .viewedAt)
            try container.encode(channel, forKey: .channel)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.channelId = try container.decode(ChannelId.self, forKey: .channelId)
            self.viewedAt = try container.decode(Date.self, forKey: .viewedAt)
            self.channel = try container.decode(Channel.self, forKey: .channel)
        }
    }
}
