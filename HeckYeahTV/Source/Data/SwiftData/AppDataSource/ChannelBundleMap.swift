//
//  ChannelBundleMap.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Observation

@Observable final class ChannelBundleMap {
    
    init(map: [ChannelMap]) {
        self.map = map
        self.mapCount = map.count
    }
    
    struct ChannelMap: Hashable {
        var bundleEntryId: BundleEntryId
        var channelId: ChannelId
        var channelBundleId: ChannelBundleId
    }
    
    private(set) var map: [ChannelMap]
    private(set) var mapCount: Int
    
    func update(map: [ChannelMap]) {
        self.map = map
        self.mapCount = map.count
    }
}
