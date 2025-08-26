//
//  IPTVFetchSummary.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

// MARK: - Batch fetch summary

struct IPTVFetchSummary {
    
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
    
    var successes: [Endpoint: Int] = [:]
    var failures: [Endpoint: Error] = [:]
    var startedAt = Date()
    var finishedAt: Date = .distantPast
    var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
    
}

extension IPTVFetchSummary.Endpoint {
    
    var url: URL {
        switch self {
            case .blocklists: return URL(string: "https://iptv-org.github.io/api/blocklist.json")!
            case .categories: return URL(string: "https://iptv-org.github.io/api/categories.json")!
            case .channels: return URL(string: "https://iptv-org.github.io/api/channels.json")!
            case .countries: return URL(string: "https://iptv-org.github.io/api/countries.json")!
            case .feeds: return URL(string: "https://iptv-org.github.io/api/feeds.json")!
            case .guides: return URL(string: "https://iptv-org.github.io/api/guides.json")!
            case .languages: return URL(string: "https://iptv-org.github.io/api/languages.json")!
            case .logos: return URL(string: "https://iptv-org.github.io/api/logos.json")!
            case .regions: return URL(string: "https://iptv-org.github.io/api/regions.json")!
            case .streams: return URL(string: "https://iptv-org.github.io/api/streams.json")!
            case .subdivisions: return URL(string: "https://iptv-org.github.io/api/subdivisions.json")!
            case .timezones: return URL(string: "https://iptv-org.github.io/api/timezones.json")!
        }
    }
    
    // Where to write, as a closure that must run on the main actor.
    var write: @MainActor (inout IPTVController, [JSONSerializable]) -> Void {
        switch self {
            case .blocklists:   { $0.blocklists   = $1 as! [IPBlocklist] }
            case .categories:   { $0.categories   = $1 as! [IPCategory] }
            case .channels:     { $0.channels     = $1 as! [IPChannel] }
            case .countries:    { $0.countries    = $1 as! [Country] }
            case .feeds:        { $0.feeds        = $1 as! [IPFeed] }
            case .guides:       { $0.guides       = $1 as! [IPGuide] }
            case .languages:    { $0.languages    = $1 as! [Language] }
            case .logos:        { $0.logos        = $1 as! [IPLogo] }
            case .regions:      { $0.regions      = $1 as! [Region] }
            case .streams:      { $0.streams      = $1 as! [IPStream] }
            case .subdivisions: { $0.subdivisions = $1 as! [Subdivision] }
            case .timezones:    { $0.timezones    = $1 as! [Timezone] }
        }
    }
}
