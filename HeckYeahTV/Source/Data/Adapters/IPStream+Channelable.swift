//
//  IPStream+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

extension IPStream: Channelable {
    var idHint: String { id }
    var sortHint: String { String.concat(title, channelId, separator: "::") }
    var titleHint: String { title }
    var numberHint: String? { channelId }
    var urlHint: URL { url }
    var qualityHint: StreamQuality { qualityHint(quality) }
    var hasDRMHint: Bool { false }
    var sourceHint: ChannelSource { ChannelSource.ipStream }
    
    private func qualityHint(_ quality: String?) -> StreamQuality {
        guard let quality else {
            return .unknown
        }
        
        let q = StreamQuality.convertToStreamQuality(quality)
        return q
    }
}
