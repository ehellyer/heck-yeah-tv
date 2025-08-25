//
//  GuideStore.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//

import SwiftUI

@MainActor
final class GuideStore: ObservableObject {
    @Published private(set) var channels: [GuideChannel] = []
    @Published var favoriteIds: Set<String> = []
    @Published var showFavoritesOnly = false
    
    @Published private(set) var selectedId: String?
    @Published private(set) var lastPlayedId: String?
    
    // Simple persistence keys
    private let favoritesKey = "guide.favorites"
    private let lastKey = "guide.last"
    
    init() {
        loadPersistence()
    }
    
    func load(streams: [IPStream], tuner: [Channel]) {
        channels = GuideBuilder.build(streams: streams, tunerChannels: tuner)
        // Prune favorites that no longer exist
        favoriteIds = favoriteIds.intersection(Set(channels.map(\.id)))
        if let sid = selectedId, !channels.contains(where: { $0.id == sid }) { selectedId = nil }
        if let lid = lastPlayedId, !channels.contains(where: { $0.id == lid }) { lastPlayedId = nil }
    }
    
    func toggleFavorite(_ channel: GuideChannel) {
        if favoriteIds.contains(channel.id) {
            favoriteIds.remove(channel.id)
        } else {
            favoriteIds.insert(channel.id)
        }
        saveFavorites()
    }
    
    func select(_ channel: GuideChannel) {
        // update last→selected
        if selectedId != channel.id {
            lastPlayedId = selectedId
            selectedId = channel.id
            saveLast()
        }
    }
    
    func switchToLastChannel() {
        guard let last = lastPlayedId, let current = selectedId, last != current else { return }
        // swap
        let temp = selectedId
        selectedId = lastPlayedId
        lastPlayedId = temp
        saveLast()
    }
    
    var visibleChannels: [GuideChannel] {
        showFavoritesOnly ? channels.filter { favoriteIds.contains($0.id) } : channels
    }
    
    func isFavorite(_ channel: GuideChannel) -> Bool {
        favoriteIds.contains(channel.id)
    }
    
    private func loadPersistence() {
        let d = UserDefaults.standard
        if let data = d.array(forKey: favoritesKey) as? [String] {
            favoriteIds = Set(data)
        }
        lastPlayedId = d.string(forKey: lastKey)
    }
    
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteIds), forKey: favoritesKey)
    }
    
    private func saveLast() {
        UserDefaults.standard.set(lastPlayedId, forKey: lastKey)
    }
}
