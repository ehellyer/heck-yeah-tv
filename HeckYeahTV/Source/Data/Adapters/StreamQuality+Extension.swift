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
        if ["240p", "360p", "480i", "480p", "576i", "576p"].contains(format) {
            return .sd
        } else if ["720p", "1080i", "1080p"].contains(format) {
            return .fhd
        } else if ["2160i", "2160p"].contains(format) {
            return .uhd4k
        } else if ["4320i", "4320p"].contains(format) {
            return .uhd8k
        } else {
            return .unknown
        }
    }
}
