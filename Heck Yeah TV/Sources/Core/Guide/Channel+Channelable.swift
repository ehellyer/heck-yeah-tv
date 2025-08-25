//
//  Channel+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//

import Foundation

extension Channel: Channelable {
    var idHint: String { guideNumber + "::" + guideName }
    var titleHint: String { guideName }
    var numberHint: String? { guideNumber }
    var urlHint: URL { url }
    var isHDHint: Bool { isHD }
    var hasDRMHint: Bool { hasDRM }
}
