//
//  Channel+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

extension Channel: Channelable {
    var idHint: String { String.concat(guideNumber, guideName, separator: "::") }
    var titleHint: String { guideName }
    var numberHint: String? { guideNumber }
    var urlHint: URL { url }
    var isHDHint: Bool { isHD }
    var hasDRMHint: Bool { hasDRM }
}
