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
    
    init() {
        // Load and initialize channel data. Cheers 🥃
        
        
        
        let processInfo = ProcessInfo.processInfo
        let appName = processInfo.processName
        var rootPath = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first!
        rootPath.append(component: appName)
        rootPath.append(component: "ChannelData")
        
        path = rootPath.appendingPathComponent("ChannelList")
        path.appendPathExtension("json")
        try? FileManager.default.createDirectory(atPath: rootPath.path, withIntermediateDirectories: true, attributes: nil)
        
        let data = try? Data.init(contentsOf: path)
        let channels: [GuideChannel] = (try? [GuideChannel].initialize(jsonData: data)) ?? []
        self._channels = channels
        self.favoriteChannelIds = self.channels.filter(\.isFavorite).map(\.id)
        self._filteredChannels = self._channels.filter { self.favoriteChannelIds.contains($0.id) }
    }
        
    //MARK: - Private API

    private var path: URL
    private var _channels: [GuideChannel] = []
    private var _filteredChannels: [GuideChannel] = []
    private var favoriteChannelIds: [String] = []
    private var isSaving = false
    private var savePending = false
    private var saveDebounceTask: Task<Void, Never>?
    private let saveDebounceDelay: Duration = .milliseconds(350)
    
    private func scheduleSave() {
        // Cancel any previously scheduled save task and schedule a new task restarting the debounce delay.
        saveDebounceTask?.cancel()
        saveDebounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: saveDebounceDelay)
            await self.serialSave()
        }
    }
    
    /// Coalesces concurrent callers; if another change lands while saving,
    /// we schedule one more save afterward.
    private func serialSave() async {
        if isSaving {
            savePending = true
            return
        }
        isSaving = true
        
        defer {
            isSaving = false
            if savePending {
                savePending = false
                scheduleSave()
            }
        }
        
        // Snapshot before any awaits
        let snapshot = _channels
        
        do {
            // Because it is large, encode off the main thread.
            let data = try await Task.detached(priority: .utility) {
                try snapshot.toJSONData()
            }.value
            
            // Atomic write off the main thread
            try await Task.detached(priority: .utility) {
                try data.write(to: self.path, options: .atomic)
            }.value
        } catch {
            // TODO: log or surface error
            print("Error: Unable to save changes to Channels to disk. Error: \(error)")
        }
    }
    
    /// An array of played channels treated as a FIFO stack.
    private func addRecentlyPlayed(channel: GuideChannel) {
        var _recentlyPlayedList = UserDefaults.recentlyPlayed
        _recentlyPlayedList.insert(channel, at: 0)
        // Recent list limited to 10 channels.
        UserDefaults.recentlyPlayed = Array(_recentlyPlayedList.prefix(10))
    }

    //MARK: - Internal API - Observable properties

    var isPlaying: Bool = true
    
    var isGuideVisible: Bool = false
    
    var selectedTab: TabSection {
        get {
            access(keyPath: \.selectedTab)
            return UserDefaults.lastTabSelected
        }
        set {
            withMutation(keyPath: \.selectedTab) {
                UserDefaults.lastTabSelected = newValue
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
                self._filteredChannels = self._channels.filter { self.favoriteChannelIds.contains($0.id) }
                UserDefaults.showFavorites = newValue
            }
        }
    }

    private(set) var channels: [GuideChannel] {
        get {
            access(keyPath: \.channels)
            return self.showFavoritesOnly ? self._filteredChannels : self._channels
        }
        set {
            withMutation(keyPath: \.channels) {
                self._channels = newValue
            }
        }
    }

    //MARK: - Internal API - Load data / Persist data
    
    /// Call this when app is going to background to force a save immediately.
    func flushSavesNow() async {
        saveDebounceTask?.cancel()
        await serialSave()
    }
    
    func load(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) async {
        let c = GuideBuilder.build(streams: streams,
                                   tunerChannels: tunerChannels,
                                   previouslyDiscovered: _channels)
        
        self._filteredChannels = c.filter { $0.isFavorite }
        self.favoriteChannelIds = self._filteredChannels.filter(\.isFavorite).map(\.id)
        
        channels = c
        scheduleSave()
    }
    
    //MARK: - Internal API - Channels

    var selectedChannel: GuideChannel? {
        return channels.first(where: { $0.isPlaying == true })
    }
    
    /// An array of played channels treated as a FIFO stack.
    var recentlyPlayed: [GuideChannel] {
        return UserDefaults.recentlyPlayed
    }
    
    /// Returns the most recently played channel from the recently played list.
    var lastPlayed: GuideChannel? {
        return recentlyPlayed.first
    }
    
    func setPlayingChannel(_ channel: GuideChannel) {
        let indexes = _channels.indices.filter({ _channels[$0].isPlaying == true })
        for index in indexes {
            _channels[index].isPlaying = false
        }
        
        if let index = _channels.firstIndex(where: {$0.id == channel.id }) {
            _channels[index].isPlaying = true
            self.isPlaying = true
            self.addRecentlyPlayed(channel: channel)
        }
        scheduleSave()
    }
    
    func toggleFavorite(_ channel: GuideChannel) {
        guard let channelIndex = _channels.firstIndex(where: {$0.id == channel.id }) else { return }
        if let favIndex = favoriteChannelIds.firstIndex(where: { $0 == channel.id}) {
            favoriteChannelIds.remove(at: favIndex)
            _channels[channelIndex].isFavorite = false
        } else {
            favoriteChannelIds.append(channel.id)
            _channels[channelIndex].isFavorite = true
        }
        scheduleSave()
    }
}
