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
    
    init(id: ChannelBundleId,
         map: [ChannelId]) {
        
        self.id = id
        self.map = map
        self.mapCount = map.count
    }
    
    private(set) var id: ChannelBundleId
    private(set) var map: [ChannelId]
    private(set) var mapCount: Int
    
    func update(id: ChannelBundleId,
                map: [ChannelId]) {
        self.id = id
        self.map = map
        self.mapCount = map.count
    }
}
