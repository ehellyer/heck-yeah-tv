//
//  GuideChannel.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//

import Foundation

struct GuideChannel: Identifiable, Hashable, Sendable {
    
    let id: String
    let title: String
    let number: String?
    let url: URL
    let isHD: Bool
    let hasDRM: Bool
    let source: ChannelSource
    
    init(_ item: Channelable, source: ChannelSource) {
        
        id = Self.normalizeIdentity(url: item.urlHint)
        title = item.titleHint
        number = item.numberHint
        url = item.urlHint
        isHD = item.isHDHint
        hasDRM = item.hasDRMHint
        self.source = source
    }
    
    private static func normalizeIdentity(url: URL) -> String {
        return "u:\(url.host ?? "h")\(url.path)"
    }
}
