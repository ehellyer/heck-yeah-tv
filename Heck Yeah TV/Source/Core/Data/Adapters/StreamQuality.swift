//
//  StreamQuality.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Hellfire

/// Coarse classification of a stream’s video resolution tier.
///
/// This enum is intentionally broad so sources with slightly different pixel dimensions
/// can still map to a consistent user-facing quality label.
enum StreamQuality: JSONSerializable, Codable {
    
    static let streamQualityViewTagId: Int = 23456604455
    
    /// **Standard Definition** — typically ≤ 480p (e.g., 640×480).
    /// Suitable for legacy devices or very limited bandwidth.
    case sd
    
    /// **Full High Definition (1080p)** — usually 1920×1080.
    /// Common modern baseline; good quality at moderate bitrates.
    case fhd
    
    /// **Ultra High Definition (4K)** — approximately 3840×2160.
    /// Higher clarity; requires capable decoder and higher bandwidth.
    case uhd4k
    
    /// **Ultra High Definition (8K)** — approximately 7680×4320.
    /// Rare in the wild; extremely demanding on bandwidth/decoding.
    case uhd8k
    
    /// Quality not reported or cannot be inferred from the source metadata.
    /// Use as a safe fallback when the provider omits resolution details.
    case unknown
}

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
