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
    var qualityHint: Quality { get }
    var hasDRMHint: Bool { get }
}

enum Quality: JSONSerializable {
    
    case sd
    case fhd
    case uhd4k
    case uhd8k
    case unknown
    
    var name: String? {
        switch self {
            case .sd:
                return "SD"
            case .fhd:
                return "HD"
            case .uhd4k:
                return "4K"
            case .uhd8k:
                return "8K"
            case .unknown:
                return nil
        }
    }
}
