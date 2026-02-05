//
//  ChannelBundleMap.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Observation

// Index on ChannelId to return the associated BundleEntryId
typealias ChannelMap = [ChannelId: BundleEntryId]

@Observable final class ChannelBundleMap {
    
    init(channelBundleId: ChannelBundleId,
         map: ChannelMap,
         channelIds: [ChannelId]) {
        self.channelBundleId = channelBundleId
        self.map = map
        self.channelIds = channelIds
        self.mapCount = map.count
    }
    
    private(set) var channelBundleId: ChannelBundleId
    private(set) var map: ChannelMap
    private(set) var mapCount: Int
    private(set) var channelIds: [ChannelId]
    
    func update(map: ChannelMap,
                channelIds: [ChannelId]) {
        self.map = map
        self.channelIds = channelIds
        self.mapCount = map.count
    }
}
