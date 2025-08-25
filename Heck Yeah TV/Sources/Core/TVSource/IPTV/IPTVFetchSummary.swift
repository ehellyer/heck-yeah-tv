//
//  IPTVFetchSummary.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

// MARK: - Batch fetch summary

struct IPTVFetchSummary {
    enum Endpoint: String, CaseIterable, Hashable {
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
    }
    
    var successes: [Endpoint: Int] = [:]          // item count per successful endpoint
    var failures: [Endpoint: Error] = [:]         // endpoint → error
    var startedAt = Date()
    var finishedAt: Date = .distantPast
    var duration: TimeInterval { finishedAt.timeIntervalSince(startedAt) }
    var isComplete: Bool { failures.isEmpty && successes.count == Endpoint.allCases.count }
    
    var fetchList: [Endpoint] = [.streams, .channels]
}
