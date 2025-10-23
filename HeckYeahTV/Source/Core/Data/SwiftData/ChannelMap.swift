//
//  ChannelMap.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Observation

@Observable final class ChannelMap {
    
    init(map: [ChannelId], totalCount: Int) {
        self.map = map
        self.totalCount = totalCount
    }
    
    private(set) var map: [ChannelId]
    private(set) var totalCount: Int
    
    func update(with map: [ChannelId], totalCount: Int) {
        self.map = map
        self.totalCount = totalCount
    }
}
