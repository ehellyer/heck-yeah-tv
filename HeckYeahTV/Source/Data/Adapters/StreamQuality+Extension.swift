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
    
    static func convertToStreamQuality(_ format: String) -> StreamQuality {
        // Extract the numeric value (e.g., "1080p" -> 1080)
        guard let resolution = Int(format.filter { $0.isNumber }) else {
            return .unknown
        }
        
        switch resolution {
            case 0..<720:
                return .sd
            case 720..<2160:
                return .fhd
            case 2160..<4320:
                return .uhd4k
            case 4320...:
                return .uhd8k
            default:
                return .unknown
        }
    }
}
