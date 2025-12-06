//
//  StreamQuality.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData
import Hellfire

extension StreamQuality {
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

extension SchemaV1 {
    
    /// Coarse classification of a stream’s video resolution tier.
    ///
    /// This enum is intentionally broad so sources with slightly different pixel dimensions
    /// can still map to a consistent user-facing quality label.
    enum StreamQuality: JSONSerializable {
        
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
        
        func migrateToV2() -> SchemaV2.StreamQuality {
            switch self {
                case .sd:
                    return .sd
                case .fhd:
                    return .fhd
                case .uhd4k:
                    return .uhd4k
                case .uhd8k:
                    return .uhd8k
                case .unknown:
                    return .unknown
            }
        }
    }
}

extension SchemaV2 {
    
    /// Coarse classification of a stream’s video resolution tier.
    ///
    /// This enum is intentionally broad so sources with slightly different pixel dimensions
    /// can still map to a consistent user-facing quality label.
    enum StreamQuality: JSONSerializable {
        
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

        func migrateToV3() -> SchemaV3.StreamQuality {
            switch self {
                case .sd:
                    return .sd
                case .fhd:
                    return .fhd
                case .uhd4k:
                    return .uhd4k
                case .uhd8k:
                    return .uhd8k
                case .unknown:
                    return .unknown
            }
        }
    }
}

extension SchemaV3 {
    
    /// Coarse classification of a stream’s video resolution tier.
    ///
    /// This enum is intentionally broad so sources with slightly different pixel dimensions
    /// can still map to a consistent user-facing quality label.
    enum StreamQuality: JSONSerializable {
        
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
        
        
        func migrateToV4() -> SchemaV4.StreamQuality {
            switch self {
                case .sd:
                    return .sd
                case .fhd:
                    return .fhd
                case .uhd4k:
                    return .uhd4k
                case .uhd8k:
                    return .uhd8k
                case .unknown:
                    return .unknown
            }
        }
    }
}

extension SchemaV4 {
    
    /// Coarse classification of a stream’s video resolution tier.
    ///
    /// This enum is intentionally broad so sources with slightly different pixel dimensions
    /// can still map to a consistent user-facing quality label.
    enum StreamQuality: JSONSerializable {
        
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
}
