//
//  SwiftDataController.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/9/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@MainActor @Observable
final class SwiftDataController: SwiftDataControllable {

    init() {
        let _viewContext = DataPersistence.shared.viewContext
        self.viewContext = _viewContext
        try? self.bootStrap()
    }
    
    deinit {
        rebuildTask?.cancel()
    }

    func toggleFavorite(for channelId: ChannelId) {
        
        let context = self.viewContext
        
        do {
            let predicate = #Predicate<IPTVFavorite> { $0.id == channelId }
            var descriptor = FetchDescriptor<IPTVFavorite>(predicate: predicate)
            descriptor.fetchLimit = 1
            if let fav: IPTVFavorite = try context.fetch(descriptor).first {
                fav.isFavorite.toggle()
            } else {
                context.insert(IPTVFavorite(id: channelId, isFavorite: true))
            }
            if context.hasChanges {
                try context.save()
            }
        } catch {
            logError("Unable to fetch favorite for channelId: \(channelId)")
        }
    }
    
    func isFavorite(channelId: ChannelId) -> Bool {
        
        let context = self.viewContext
        
        do {
            let predicate = #Predicate<IPTVFavorite> { $0.id == channelId }
            var descriptor = FetchDescriptor<IPTVFavorite>(predicate: predicate)
            descriptor.fetchLimit = 1
            let favChannel = try context.fetch(descriptor).first
            return favChannel?.isFavorite ?? false
        } catch {
            logError("Unable to fetch favorite for channelId: \(channelId)")
            return false
        }
    }
    
    static func predicateBuilder(favoriteIds: Set<ChannelId>? = nil,
                                 searchTerm: String? = nil,
                                 countryCode: CountryCode,
                                 categoryId: CategoryId? = nil) -> Predicate<IPTVChannel> {
        
        var conditions: [Predicate<IPTVChannel>] = []
        
        if let favoriteIds, !favoriteIds.isEmpty {
            conditions.append(#Predicate<IPTVChannel> { channel in
                favoriteIds.contains(channel.id)
            })
        }
        if let searchTerm, searchTerm.count > 0 {
            conditions.append( #Predicate<IPTVChannel> { $0.title.localizedStandardContains(searchTerm) })
        }
        //if let countryCode {
            conditions.append( #Predicate<IPTVChannel> { $0.country == countryCode || $0.country == "ANY" }) // "ANY" support local LAN tuners which get returned regardless of current country selection.
        //}
//        if let categoryId {
//            conditions.append( #Predicate<IPTVChannel> { $0.categories.contains(categoryId) })
//        }
        
        // Combine conditions using '&&' (AND)
        if conditions.isEmpty {
            return #Predicate { _ in true } // Return a predicate that always evaluates to true if no conditions
        } else {
            let compoundPredicate = conditions.reduce(#Predicate { _ in true }) { current, next in
                #Predicate { current.evaluate($0) && next.evaluate($0) }
            }
            return compoundPredicate
        }
    }
    
    //MARK: - Private API Properties
    
    @ObservationIgnored
    private var viewContext: ModelContext
    
    @ObservationIgnored
    private var rebuildTask: Task<Void, Never>?

    //MARK: - Private API - Bootstrapping.
    
    private var bootstrapStarted: Bool = false
    
    private func bootStrap() throws {
        guard bootstrapStarted == false else { return }
        bootstrapStarted = true
        try rebuildChannelMap()
    }
    
    //MARK: - Private API Debounced Channel Map Rebuilding
    
    /// Schedules a channel map rebuild with debouncing to prevent excessive rebuilds.
    ///
    /// This method cancels any pending rebuild and schedules a new one after a 300ms delay.
    /// The delay is particularly useful for search term changes where users are actively typing.
    private func scheduleChannelMapRebuild() async {
        // Cancel any existing rebuild task
        rebuildTask?.cancel()
        
        // Schedule a new rebuild after debounce delay
        rebuildTask = Task { @MainActor in
            // Wait for debounce period (300ms is a sweet spot for search-as-you-type)
            try? await Task.sleep(for: .milliseconds(300))
            
            // Check if task was cancelled during sleep
            guard !Task.isCancelled else { return }
            
            // Rebuild the channel map with current filter values
            do {
                try rebuildChannelMap()
            } catch {
                logError("Failed to rebuild channel map: \(error)")
            }
        }
    }
    
    private func rebuildChannelMap() throws {
        
        let context = self.viewContext
        
        if context.hasChanges {
            logWarning("Unsaved changes prior to building channel map, saving...")
            try context.save()
        }
        
        logDebug("Building Channel Map... 🇺🇸")
        
        var channelsDescriptor: FetchDescriptor<IPTVChannel> = FetchDescriptor<IPTVChannel>(
            sortBy: [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
        )
        
        var favoriteIds: Set<ChannelId>? = nil
        if showFavoritesOnly == true {
            let favoritesDescriptor = FetchDescriptor<IPTVFavorite>(
                predicate: #Predicate { $0.isFavorite == true }
            )
            let favorites = try context.fetch(favoritesDescriptor)
            favoriteIds = Set(favorites.map(\.id))
        }
        
        let predicate: Predicate<IPTVChannel> = Self.predicateBuilder(favoriteIds: favoriteIds,
                                                                      searchTerm: searchTerm,
                                                                      countryCode: selectedCountry,
                                                                      categoryId: selectedCategory)
        
        channelsDescriptor.predicate = predicate
        
        let channels: [IPTVChannel] = try context.fetch(channelsDescriptor)
        let map: [ChannelId] = channels.map { $0.id }
        
        self.guideChannelMap = ChannelMap(map: map)
        
        logDebug("Channel map built.  Total Channels: \(map.count) 🏁")
    }

    //MARK: - Internal API - guide channel map
    
    private(set) var guideChannelMap: ChannelMap = ChannelMap(map: [])
    
    //MARK: - Internal API - Channel Filter Provider implementation
    
    /// Only show the good channels. Life's too short for the rest.
    var showFavoritesOnly: Bool {
        get {
            access(keyPath: \.showFavoritesOnly)
            return UserDefaults.showFavoritesOnly
        }
        set {
            if showFavoritesOnly != newValue {
                Task { @MainActor in
                    await scheduleChannelMapRebuild()
                }
            }
            withMutation(keyPath: \.showFavoritesOnly) {
                UserDefaults.showFavoritesOnly = newValue
            }
        }
    }
    
    /// Which country? All of them? None of them? The suspense is killing me.
    var selectedCountry: CountryCode {
        get {
            access(keyPath: \.selectedCountry)
            return UserDefaults.selectedCountry
        }
        set {
            if selectedCountry != newValue {
                Task { @MainActor in
                    await scheduleChannelMapRebuild()
                }
            }
            withMutation(keyPath: \.selectedCountry) {
                UserDefaults.selectedCountry = newValue
            }
        }
    }
    
    /// Filter by category? Or embrace the chaos of all channels at once?
    var selectedCategory: CategoryId? {
        didSet {
            guard selectedCategory != oldValue else { return }
            Task { @MainActor in
                await scheduleChannelMapRebuild()
            }
        }
    }

    /// Filter by channel title search term. Because scrolling through 10,000 channels wasn't tedious enough.
    var searchTerm: String? {
        didSet {
            guard searchTerm != oldValue else { return }
            Task { @MainActor in
                await scheduleChannelMapRebuild()
            }
        }
    }
}
