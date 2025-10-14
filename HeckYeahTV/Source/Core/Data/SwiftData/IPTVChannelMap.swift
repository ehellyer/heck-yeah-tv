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

@Model final class IPTVChannelMap {
    
    init(map: [MapIndex: ChannelId]) {
        self.singletonKey = IPTVChannelMap.singletonKeyValue
        self.map = map
        self.totalCount = map.count
        self.reverseMap = Dictionary(uniqueKeysWithValues: map.map { ($0.value, $0.key) })
    }
    
    @Attribute(.unique) private(set) var singletonKey: String
    private(set) var map: [MapIndex: ChannelId]
    private(set) var reverseMap: [ChannelId: MapIndex]
    @Transient private(set) var totalCount: Int = 0
}

extension IPTVChannelMap {
    // Centralized constant to avoid typos across the app.  
    static let singletonKeyValue = "IPTVChannelMapSingleton"
}
