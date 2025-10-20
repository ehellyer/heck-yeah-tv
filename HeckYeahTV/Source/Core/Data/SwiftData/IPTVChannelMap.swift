//
//  IPTVChannelMap.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/14/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

let channelMapKey: String = "IPTVChannelMapSingleton"

@Model final class IPTVChannelMap: Identifiable {

    init(map: [ChannelId]) {
//    init(map: [ChannelId], reverseLookup: [ChannelId: Int]) {
        self.id = channelMapKey
        self.map = map
//        self.reverseLookup = reverseLookup
        self.totalCount = map.count
    }

    @Attribute(.unique) private(set) var id: String
    private(set) var map: [ChannelId]
//    private(set) var reverseLookup: [ChannelId: Int]
    private(set) var totalCount: Int = 0
    
    
//    func index(for channelId: ChannelId) -> Int {
//        return reverseLookup[channelId]!
//    }
}
