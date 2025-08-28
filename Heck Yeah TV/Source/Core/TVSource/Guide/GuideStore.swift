//
//  GuideStore.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Observation

@Observable
final class GuideStore {
    
    //MARK: - GuideStore lifecycle
    
    init(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) {
        favorites = UserDefaults.favorites
        lastPlayedChannel = UserDefaults.lastPlayed
        selectedChannel = lastPlayedChannel
        load(streams: streams, tunerChannels: tunerChannels)
    }
    
    //MARK: - Private API
    
    private var channels: [GuideChannel] = []
    
    private func saveFavorites() {
        UserDefaults.favorites = favorites
    }
    
    private func saveLast() {
        UserDefaults.lastPlayed = lastPlayedChannel
    }
    
    //MARK: - Internal API - Observable properties
    
    private(set) var lastPlayedChannel: GuideChannel?
    private(set) var favorites: [GuideChannel] = []
    var showFavoritesOnly = false
    var isGuideVisible: Bool = true
    var visibleChannels: [GuideChannel] {
        showFavoritesOnly ? channels.filter { favorites.contains($0) } : channels
    }
    
    //MARK: - Internal API

    var selectedChannel: GuideChannel? {
        didSet {
            if selectedChannel?.id != lastPlayedChannel?.id {
                lastPlayedChannel = selectedChannel
                saveLast()
            }
        }
    }

    func load(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) {
        channels = GuideBuilder.build(streams: streams, tunerChannels: tunerChannels)
        
        // Pruning if channel no longer exists.
        favorites = Array(Set(favorites).intersection(Set(channels)))
        if let _selectedChannel = selectedChannel, !channels.contains(where: { $0.id == _selectedChannel.id }) {
            selectedChannel = nil
        }
        if let _lastPlayedChannel = lastPlayedChannel, !channels.contains(where: { $0.id == _lastPlayedChannel.id }) {
            lastPlayedChannel = nil
        }
    }
    
    func toggleFavorite(_ channel: GuideChannel) {
        if favorites.contains(channel) {
            favorites.removeAll(where: { $0 == channel })
        } else {
            favorites.append(channel)
        }
        saveFavorites()
    }
    
    func switchToLastChannel() {
        guard let last = lastPlayedChannel, let current = selectedChannel, last != current else { return }
        // swap
        let temp = selectedChannel
        selectedChannel = lastPlayedChannel
        lastPlayedChannel = temp
        saveLast()
    }
    
    func isFavorite(_ channel: GuideChannel) -> Bool {
        favorites.contains(channel)
    }


}
