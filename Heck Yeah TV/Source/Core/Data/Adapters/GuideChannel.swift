//
//  GuideChannel.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

struct GuideChannel: Identifiable, Hashable, Sendable, JSONSerializable {
    
    let id: String
    let sortHint: String
    let title: String
    let number: String?
    let url: URL
    let quality: Quality
    let hasDRM: Bool
    let source: ChannelSource
    
    init(_ item: Channelable, channelSource: ChannelSource) {
        
        id = item.idHint
        sortHint = item.sortHint
        title = item.titleHint
        number = item.numberHint
        url = item.urlHint
        quality = item.qualityHint
        hasDRM = item.hasDRMHint
        source = channelSource
    }
}
