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

    init() {
        favorites = UserDefaults.favorites
        lastPlayedChannel = UserDefaults.lastPlayed
        selectedChannel = lastPlayedChannel
        if selectedChannel != nil {
            isPlaying = true
        }
    }
    
    init(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) {
        favorites = UserDefaults.favorites
        lastPlayedChannel = UserDefaults.lastPlayed
        selectedChannel = lastPlayedChannel
        if selectedChannel != nil {
            isPlaying = true
        }
        load(streams: streams, tunerChannels: tunerChannels)
    }
    
    //MARK: - Private API
    
    private var _selectedChannelBakStore: GuideChannel?
    @ObservationIgnored private var channels: [GuideChannel] = []
    private var favorites: [GuideChannel] = []
    
    //MARK: - Internal API - Observable properties

    var isPlaying: Bool = false
    var isGuideVisible: Bool = false
    var selectedTab: TabSection {
        get {
            access(keyPath: \.selectedTab)
            return UserDefaults.lastTabSelected ?? .last
        }
        set {
            withMutation(keyPath: \.selectedTab) {
                UserDefaults.lastTabSelected = newValue
            }
        }
    }
    
    private(set) var lastPlayedChannel: GuideChannel? {
        get {
            access(keyPath: \.lastPlayedChannel)
            return UserDefaults.lastPlayed
        }
        set {
            withMutation(keyPath: \.lastPlayedChannel) {
                UserDefaults.lastPlayed = newValue
            }
        }
    }
    
    var showFavoritesOnly: Bool {
        get {
            access(keyPath: \.showFavoritesOnly)
            return UserDefaults.showFavorites
        }
        set {
            withMutation(keyPath: \.showFavoritesOnly) {
                UserDefaults.showFavorites = newValue
            }
        }
    }
    
    var visibleChannels: [GuideChannel] {
        return showFavoritesOnly ? channels.filter { favorites.contains($0) } : channels
    }
    
    //MARK: - Internal API

    var selectedChannelIndex: Int? {
        guard let selectedChannel = _selectedChannelBakStore else { return nil }
        return visibleChannels.firstIndex(of: selectedChannel)
    }
    
    var selectedChannel: GuideChannel? {
        
        get {
            access(keyPath: \.selectedChannel)
            return _selectedChannelBakStore
        }
        set {
            if _selectedChannelBakStore != newValue {
                // Tell the Observation system this property is mutating:
                withMutation(keyPath: \.selectedChannel) {
                    _selectedChannelBakStore = newValue
                    lastPlayedChannel = newValue
                }
            }
        }
    }

    func load(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) {
        channels = GuideBuilder.build(streams: streams, tunerChannels: tunerChannels)
        
        // Pruning favorites, selected channel and last played channel: If channel no longer exists.
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
        UserDefaults.favorites = favorites
    }
    
    func switchToLastChannel() {
        guard let last = lastPlayedChannel, let current = selectedChannel, last != current else { return }
        let temp = selectedChannel
        selectedChannel = lastPlayedChannel
        lastPlayedChannel = temp
    }
    
    func isFavorite(_ channel: GuideChannel) -> Bool {
        favorites.contains(channel)
    }
}
