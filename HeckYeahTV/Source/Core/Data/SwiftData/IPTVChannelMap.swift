//
//  IPTVChannelMap.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/14/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

typealias MapIndex = Int

@Model final class IPTVChannelMap: Identifiable {
    
    init(map: [ChannelId]) {
        self.id = channelMapKey
        self.map = map
        self.totalCount = map.count
    }
    
    @Attribute(.unique) private(set) var id: String
    private(set) var map: [ChannelId]
    private(set) var totalCount: Int = 0
}
