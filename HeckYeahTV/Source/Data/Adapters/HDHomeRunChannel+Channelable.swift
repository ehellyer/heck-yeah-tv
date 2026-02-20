//
//  HDHomeRunChannel+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

extension HDHomeRunChannel: Channelable {
    var idHint: String { id }
    var guideIdHint: String? { guideNumber } 
    var sortHint: String { String.concat(guideNumber, guideName, separator: "::") }
    var titleHint: String { guideName }
    var numberHint: String? { guideNumber }
    var urlHint: URL { url }
    var qualityHint: StreamQuality { (isHD ? .fhd : .sd) }
    var hasDRMHint: Bool { hasDRM }
    var deviceIdHint: HDHomeRunDeviceId { deviceId }
    var logoURLHint: URL? { logoURL }
}
