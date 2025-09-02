//
//  IPStream+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

extension IPStream: Channelable {
    var idHint: String { String.stableHashHex(url.absoluteString, title) }
    var sortHint: String { String.concat(title, channelId, separator: "::") }
    var titleHint: String { title }
    var numberHint: String? { channelId }
    var urlHint: URL { url }
    var qualityHint: Quality {
        guard let quality else {
            return .unknown
        }
        
        if quality.contains("480") {
            //(680x480)
            return .sd
        } else if quality.contains("720") || quality.contains("1080") {
            //(1920x1080)
            return .fhd
        } else if quality.contains("2160") {
            //(3840x2160)
            return .uhd4k
        } else if quality.contains("4320") {
            //(7680x4320)
            return .uhd8k
        } else {
            return .unknown
        }
    }
    var hasDRMHint: Bool { false }
}
