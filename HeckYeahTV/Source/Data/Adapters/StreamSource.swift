//
//  StreamSource.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

// MARK: - Batch fetch summary

struct StreamSource {
    
    enum Endpoint: String, Hashable {
        case blocklists
        case categories
        case channels
        case countries
        case feeds
        case guides
        case languages
        case logos
        case regions
        case streams
        case subdivisions
        case timezones
    }
    
    var summary: FetchSummary = FetchSummary()
    
}

extension StreamSource.Endpoint {
    
    var url: URL {
        let hostPath: String = "https://iptv-org.github.io/api/"
        var resource: String = ""
        
        switch self {
            case .blocklists: resource = "blocklist.json"
            case .categories: resource = "categories.json"
            case .channels: resource = "channels.json"
            case .countries: resource = "countries.json"
            case .feeds: resource = "feeds.json"
            case .guides: resource = "guides.json"
            case .languages: resource = "languages.json"
            case .logos: resource = "logos.json"
            case .regions: resource = "regions.json"
            case .streams: resource = "streams.json"
            case .subdivisions: resource = "subdivisions.json"
            case .timezones: resource = "timezones.json"
        }
        
        return URL(string: "\(hostPath)\(resource)")!
    }
}
