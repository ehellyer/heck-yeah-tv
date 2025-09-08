//
//  ChannelStream.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/7/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

// MARK: - Joined result

/// A simple pair returned by the join. Adjust as needed.
struct ChannelStream: JSONSerializable {
    let channel: IPChannel
    let stream: IPStream
}

extension ChannelStream: Hashable {
    static func == (lhs: ChannelStream, rhs: ChannelStream) -> Bool {
        lhs.channel.channelId == rhs.channel.channelId &&
        lhs.stream.url == rhs.stream.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(channel.channelId)
        hasher.combine(stream.url)
    }
}

// MARK: - Filters

/// Configure which channel properties must match.
/// If a set is nil/empty, that clause is not applied.
struct ChannelFilters {
    /// Channel country must be one of these (e.g., ["US", "UK"])
    var countries: Set<String>?
    
    /// Channel categories must CONTAIN AT LEAST ONE of these (case-insensitive)
    var categoriesAnyOf: Set<String>?
    
    /// Channel network must be one of these (case-insensitive compare)
    var networks: Set<String>?
    
    /// Channel owners must CONTAIN AT LEAST ONE of these (case-insensitive compare)
    var ownersAnyOf: Set<String>?
    
    init(countries: Set<String>? = nil,
         categoriesAnyOf: Set<String>? = nil,
         networks: Set<String>? = nil,
         ownersAnyOf: Set<String>? = nil) {
        self.countries = countries?.map { $0.uppercased() }.reduce(into: Set<String>()) { $0.insert($1) }
        self.categoriesAnyOf = categoriesAnyOf?.normalizedSet()
        self.networks = networks?.normalizedSet()
        self.ownersAnyOf = ownersAnyOf?.normalizedSet()
    }
    
    func matches(_ c: IPChannel) -> Bool {
        // Country (exact, typically 2-letter)
        let countryOK: Bool = {
            guard let allowed = countries, !allowed.isEmpty else { return true }
            return allowed.contains(c.country.uppercased())
        }()
        
        // Categories (any-overlap, case-insensitive)
        let categoriesOK: Bool = {
            guard let required = categoriesAnyOf, !required.isEmpty else { return true }
            let have = Set((c.categories ?? []).map { $0.normalized() })
            return !have.isEmpty && !have.isDisjoint(with: required)
        }()
        
        // Network (exact among allowed, case-insensitive)
        let networkOK: Bool = {
            guard let allowed = networks, !allowed.isEmpty else { return true }
            guard let n = c.network?.normalized(), !n.isEmpty else { return false }
            return allowed.contains(n)
        }()
        
        // Owners (any-overlap, case-insensitive)
        let ownersOK: Bool = {
            guard let required = ownersAnyOf, !required.isEmpty else { return true }
            let have = Set((c.owners ?? []).map { $0.normalized() })
            return !have.isEmpty && !have.isDisjoint(with: required)
        }()
        
        // AND across the four clauses
        return countryOK && categoriesOK && networkOK && ownersOK
    }
}

// MARK: - Join + filter

/// Inner-joins streams to channels by channelId and applies channel filters.
/// Returns only pairs that both join AND pass all filter clauses.
func joinStreamsWithChannels(streams: [IPStream], channels: [IPChannel], filters: ChannelFilters) -> [ChannelStream] {
    
    // Index channels by channelId for O(1) lookup
    let channelById: [String: IPChannel] = Dictionary(uniqueKeysWithValues: channels.map { ($0.channelId, $0) })
    
    // Inner join + filter
    return streams.compactMap { s in
        guard let id = s.channelId, let ch = channelById[id] else { return nil } // inner join only
        guard filters.matches(ch) else { return nil }
        return ChannelStream(channel: ch, stream: s)
    }
}

/// Convenience if you only want the IPStream results after the join/filter.
func filteredStreams(streams: [IPStream],
                     channels: [IPChannel],
                     filters: ChannelFilters) -> [IPStream] {
    joinStreamsWithChannels(streams: streams, channels: channels, filters: filters).map(\.stream)
}

// MARK: - Helpers

extension String {
    /// Lowercased, trimmed, diacritic-insensitive for robust comparisons.
    func normalized() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }
}

extension Set where Element == String {
    
//    static func from<S: Sequence>(_ seq: S) -> Set<String> where S.Element == String {
//        Set(seq.map { $0.normalized() })
//    }
    
    func isDisjoint(with other: Set<String>) -> Bool {
        self.intersection(other).isEmpty
    }
    
    func normalizedSet() -> Set<String>? {
        guard !self.isEmpty else { return nil }
        return Set(self.map { $0.normalized() })
    }
}
