//
//  MockSwiftDataController.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@MainActor @Observable
final class MockSwiftDataController: SwiftDataControllable {
    
    //MARK: - SwiftDataController lifecycle
    
    deinit {
        rebuildTask?.cancel()
    }

    init(viewContext: ModelContext,
         selectedCountry: CountryCode = "US",
         selectedCategory: CategoryId? = nil,
         showFavoritesOnly: Bool = false,
         searchTerm: String? = nil) {

        self.viewContext = viewContext
        self.selectedCountry = selectedCountry
        self.selectedCategory = selectedCategory
        self.showFavoritesOnly = showFavoritesOnly
        self.searchTerm = searchTerm
        
        try? self.bootStrap()
    }
    
    //MARK: - Internal API - SwiftDataControllable implementation Properties
    
    private(set) var guideChannelMap: ChannelMap = ChannelMap(map: [])
    
    //MARK: - Internal API - SwiftDataControllable implementation Functions
    
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
    
    static func predicateBuilder(favoriteIds: Set<ChannelId>?,
                                 searchTerm: String?,
                                 countryCode: CountryCode,
                                 categoryId: CategoryId?) -> Predicate<IPTVChannel> {
        
        // Keeping the predicate builder code in the same spot for now.  (Less maintenance)  Change if needed.
        SwiftDataController.predicateBuilder(favoriteIds: favoriteIds,
                                             searchTerm: searchTerm,
                                             countryCode: countryCode,
                                             categoryId:  categoryId)
    }
    
    //MARK: - Internal API - ChannelFilterable implementation Properties
    
    var showFavoritesOnly: Bool = false {
        didSet {
            guard showFavoritesOnly != oldValue else { return }
            scheduleChannelMapRebuild()
        }
    }
    
    var selectedCountry: CountryCode {
        didSet {
            guard selectedCountry != oldValue else { return }
            scheduleChannelMapRebuild()
        }
    }
    
    var selectedCategory: CategoryId? {
        didSet {
            guard selectedCategory != oldValue else { return }
            scheduleChannelMapRebuild()
        }
    }
    
    var searchTerm: String? {
        didSet {
            guard searchTerm != oldValue else { return }
            scheduleChannelMapRebuild()
        }
    }
    
    //MARK: - Internal API Functions for Preview
    
    func fetchChannel(at index: Int) -> IPTVChannel {
        let channelId = guideChannelMap.map[index]
        let predicate = #Predicate<IPTVChannel> { $0.id == channelId }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        let channel = try! viewContext.fetch(descriptor).first!
        return channel
    }
    
    //MARK: - Private API Properties
    
    @ObservationIgnored
    private var viewContext: ModelContext
    
    @ObservationIgnored
    private var rebuildTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var bootstrapStarted: Bool = false
    
    //MARK: - Private API - Functions
    
    private func bootStrap() throws {
        guard bootstrapStarted == false else { return }
        bootstrapStarted = true
        try rebuildChannelMap()
    }

    /// Schedules a channel map rebuild with debouncing to prevent excessive rebuilds.
    ///
    /// This method cancels any pending rebuild and schedules a new one after a 300ms delay.
    /// The delay is particularly useful for search term changes where users are actively typing.
    private func scheduleChannelMapRebuild() {
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
        
        channelsDescriptor.predicate = Self.predicateBuilder(favoriteIds: favoriteIds,
                                                             searchTerm: searchTerm,
                                                             countryCode: selectedCountry,
                                                             categoryId:  selectedCategory)
        
        let channels: [IPTVChannel] = try context.fetch(channelsDescriptor)
        let map: [ChannelId] = channels.map { $0.id }
        
        self.guideChannelMap = ChannelMap(map: map)
    
        logDebug("Channel map built.  Total Channels: \(map.count) 🏁")
    }
}
