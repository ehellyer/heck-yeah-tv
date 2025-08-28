//
//  IPStream+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

extension IPStream: Channelable {
    var idHint: String { UUID().uuidString }
    var sortHint: String { String.concat(channelId, title, separator: "::") }
    var titleHint: String { title }
    var numberHint: String? { channelId }
    var urlHint: URL { url }
    var qualityHint: Quality {
        guard let quality else {
            return .unknown
        }
        
        if quality.contains("480") {
            return .sd
        } else if quality.contains("720") || quality.contains("1080") {
            return .hd
        } else if quality.contains("2160") {
            return .uhd
        } else {
            return .unknown
        }
    }
    var hasDRMHint: Bool { false }
}
