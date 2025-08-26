//
//  IPStream+Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

extension IPStream: Channelable {
    var idHint: String { channelId ?? title }
    var titleHint: String { title }
    var numberHint: String? { channelId }
    var urlHint: URL { url }
    var isHDHint: Bool { (quality ?? "").contains("720") || (quality ?? "").contains("1080") }
    var hasDRMHint: Bool { false }
}
