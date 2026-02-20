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
    var guideIdHint: String? { channelId }
    var sortHint: String { String.concat(title, channelId, separator: "::") }
    var titleHint: String { title }
    var numberHint: String? { channelId }
    var urlHint: URL { url }
    var qualityHint: StreamQuality { StreamQuality.convertToStreamQuality(quality) }
    var hasDRMHint: Bool { false }
    var deviceIdHint: HDHomeRunDeviceId { IPTVImporter.iptvDeviceId }
    var logoURLHint: URL? { logoURL }
}
