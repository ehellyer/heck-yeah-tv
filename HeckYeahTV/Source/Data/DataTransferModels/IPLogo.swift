//
//  IPLogo.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source: [https://iptv-org.github.io/api/logos.json](https://iptv-org.github.io/api/logos.json)
struct IPLogo: JSONSerializable {
    
    /// Channel Id (e.g., "France3.fr")
    let channelId: String
    
    /// Feed ID if the logo is specific to a feed, otherwise `nil` (e.g., "ParisIledeFrance")
    let feedId: String?
    
    /// Keywords describing this logo variant (e.g., ["horizontal", "white"])
    let tags: [String]
    
    /// Image width in pixels (e.g., 1000)
    let width: CGFloat
    
    /// Image height in pixels (e.g., 468)
    let height: CGFloat
    
    /// Image format if specified (one of: PNG, JPEG, SVG, GIF, WebP, AVIF, APNG); otherwise `nil`
    let format: String?
    
    /// Direct URL to the logo asset
    let url: URL
}

//MARK: - JSONSerializable customization

extension IPLogo {
    
    enum CodingKeys: String, CodingKey {
        case channelId = "channel"
        case feedId = "feed"
        case tags
        case width
        case height
        case format
        case url
    }
}
