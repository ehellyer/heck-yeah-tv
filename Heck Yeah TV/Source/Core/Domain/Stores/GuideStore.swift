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
    }
    
    init(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) {
        favorites = UserDefaults.favorites
        lastPlayedChannel = UserDefaults.lastPlayed
        selectedChannel = lastPlayedChannel
        load(streams: streams, tunerChannels: tunerChannels)
    }
    
    //MARK: - Private API
    
    private var _selectedChannelBakStore: GuideChannel?
    private var channels: [GuideChannel] = []
    
    //MARK: - Internal API - Observable properties
    
    private(set) var lastPlayedChannel: GuideChannel? {
        get {
            UserDefaults.lastPlayed
        }
        set {
            UserDefaults.lastPlayed = newValue
        }
    }
    private(set) var favorites: [GuideChannel] = []
    var showFavoritesOnly = false
    var isGuideVisible: Bool = false
    var visibleChannels: [GuideChannel] {
        showFavoritesOnly ? channels.filter { favorites.contains($0) } : channels
    }
    
    //MARK: - Internal API

    var selectedChannel: GuideChannel? {
        
        get {
            return _selectedChannelBakStore
        }
        set {
            if _selectedChannelBakStore != newValue {
                // Tell the Observation system this property is mutating:
                withMutation(keyPath: \.selectedChannel) {
                    _selectedChannelBakStore = newValue
                }
            }
            
            //Handle my side effect (Because I can't use didSet in an @Observable class).
            if newValue != lastPlayedChannel {
                lastPlayedChannel = newValue
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
