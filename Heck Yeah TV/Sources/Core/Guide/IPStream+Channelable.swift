//
//  IPStream+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//

import Foundation

extension IPStream: Channelable {
    var idHint: String { channelId }
    var titleHint: String { title }
    var numberHint: String? { nil }
    var urlHint: URL { url }
    var isHDHint: Bool { (quality ?? "").contains("720") || (quality ?? "").contains("1080") }
    var hasDRMHint: Bool { false }
}
