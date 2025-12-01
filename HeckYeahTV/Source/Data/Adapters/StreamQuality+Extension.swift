//
//  StreamQuality.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Hellfire

extension StreamQuality {
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
