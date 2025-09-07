//
//  Channelable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

protocol Channelable {
    var idHint: String { get }
    var sortHint: String { get }
    var titleHint: String { get }
    var numberHint: String? { get }
    var urlHint: URL { get }
    var qualityHint: StreamQuality { get }
    var hasDRMHint: Bool { get }
}


