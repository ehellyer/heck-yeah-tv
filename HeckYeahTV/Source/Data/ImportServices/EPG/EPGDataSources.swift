//
//  EPGDataSources.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 3/26/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

enum EPGDataSources {
    
    /// EPG.pw data sources
    enum EPGpw {
        /// Global EPG for all channels (compressed)
        static let globalURL = URL(string: "https://epg.pw/xmltv/epg.xml.gz")!
        
        /// Global EPG for all channels (uncompressed)
        static let globalUncompressedURL = URL(string: "https://epg.pw/xmltv/epg.xml")!
        
        /// Lite version EPG (compressed, smaller file size)
        static let liteURL = URL(string: "https://epg.pw/xmltv/epg_lite.xml.gz")!
        
        /// Lite version EPG (uncompressed)
        static let liteUncompressedURL = URL(string: "https://epg.pw/xmltv/epg_lite.xml")!
        
        /// Returns country-specific EPG URL
        /// - Parameter countryCode: Two-letter country code (e.g., "US", "GB", "CA")
        /// - Parameter compressed: Whether to return compressed version (default: true)
        /// - Returns: URL for the country-specific EPG
        static func countryURL(_ countryCode: String, compressed: Bool = true) -> URL {
            let code = countryCode.uppercased()
            let ext = compressed ? ".xml.gz" : ".xml"
            return URL(string: "https://epg.pw/xmltv/epg_\(code)\(ext)")!
        }
    }
    
    /// Common country codes for easy reference
    enum CountryCode {
        static let unitedStates = "US"
        static let unitedKingdom = "GB"
        static let canada = "CA"
        static let australia = "AU"
        static let germany = "DE"
        static let france = "FR"
        static let india = "IN"
        static let japan = "JP"
        static let brazil = "BR"
        static let china = "CN"
        static let russia = "RU"
        static let vietnam = "VN"
        static let hongKong = "HK"
    }
}
