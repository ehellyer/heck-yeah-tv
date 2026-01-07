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

    //MARK: - SwiftDataController lifecycle
    
    deinit {
        rebuildTask?.cancel()
    }
    
    init() {
        self.viewContext = SwiftDataStack.shared.viewContext
        let descriptor = FetchDescriptor<Channel>()
        self.totalChannelCount = (try? viewContext.fetchCount(descriptor)) ?? 0
        
        try? self.bootStrap()
    }
    
    //MARK: - Internal API - SwiftDataControllable implementation
    
    private(set) var totalChannelCount: Int
    
    private(set) var channelBundleMap: ChannelBundleMap = ChannelBundleMap(id: UserDefaults.selectedChannelBundle, map: [])
    
    func channel(for channelId: ChannelId) throws -> Channel {
        let predicate = #Predicate<Channel> { $0.id == channelId }
        var fetchDescriptor = FetchDescriptor<Channel>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        guard let _program = try viewContext.fetch(fetchDescriptor).first else {
            throw GuideStoreError.noChannelFoundForId(channelId)
        }
        return _program
    }
    
    func channelPrograms(for channelId: ChannelId) -> [ChannelProgram] {
        do {
            let predicate = #Predicate<ChannelProgram> { $0.channelId == channelId }
            let startTimeSort = SortDescriptor<ChannelProgram>(\.startTime, order: .forward)
            let fetchDescriptor = FetchDescriptor<ChannelProgram>(predicate: predicate, sortBy: [startTimeSort])
            let _programs = try viewContext.fetch(fetchDescriptor)
            return _programs
        } catch {
            logError("Failed to fetch channel programs for channelId: \(channelId).  Error \(error.localizedDescription)")
            return []
        }
    }
    
    static func predicateBuilder(showFavoritesOnly: Bool,
                                 searchTerm: String?,
                                 countryCode: CountryCodeId,
                                 categoryId: CategoryId?) -> Predicate<Channel> {
        
        var conditions: [Predicate<Channel>] = []

        conditions.append( #Predicate<Channel> { $0.country == countryCode || $0.country == "ANY" }) // "ANY" support local LAN tuners which should be returned regardless of current country selection.

        if showFavoritesOnly {
            conditions.append(#Predicate<Channel> { $0.favorite != nil && $0.favorite?.isFavorite == true })
        }
        
        if let searchTerm, searchTerm.count > 0 {
            conditions.append( #Predicate<Channel> { $0.title.localizedStandardContains(searchTerm) })
        }
        
        if let categoryId {
            conditions.append( #Predicate<Channel> { channel in
                channel.categories.contains(where: { $0.categoryId == categoryId })
            })
        }
        
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
    
    //MARK: - Internal API - ChannelFilterable implementation Properties
    
    /// Only show the good channels. Life's too short for the rest.
    var showFavoritesOnly: Bool {
        get {
            access(keyPath: \.showFavoritesOnly)
            return UserDefaults.showFavoritesOnly
        }
        set {
            if showFavoritesOnly != newValue {
                Task { @MainActor in
                    await scheduleChannelBundleMapRebuild()
                }
            }
            withMutation(keyPath: \.showFavoritesOnly) {
                UserDefaults.showFavoritesOnly = newValue
            }
        }
    }
    
    /// Which country? All of them? None of them? The suspense is killing me.
    var selectedCountry: CountryCodeId {
        get {
            access(keyPath: \.selectedCountry)
            return UserDefaults.selectedCountry
        }
        set {
            if selectedCountry != newValue {
                Task { @MainActor in
                    await scheduleChannelBundleMapRebuild()
                }
            }
            withMutation(keyPath: \.selectedCountry) {
                UserDefaults.selectedCountry = newValue
            }
        }
    }
    
    /// Filter by category? Or embrace the chaos of all channels at once?
    var selectedCategory: CategoryId? {
        get {
            access(keyPath: \.selectedCategory)
            return UserDefaults.selectedCategory
        }
        set {
            if selectedCategory != newValue {
                Task { @MainActor in
                    await scheduleChannelBundleMapRebuild()
                }
            }
            withMutation(keyPath: \.selectedCategory) {
                UserDefaults.selectedCategory = newValue
            }
        }
    }
    
    /// Filter by channel title search term. Because scrolling through 10,000 channels wasn't tedious enough.
    var searchTerm: String? {
        didSet {
            guard searchTerm != oldValue else { return }
            Task { @MainActor in
                await scheduleChannelBundleMapRebuild()
            }
        }
    }
    
    //MARK: - Private API Properties
    
    @ObservationIgnored
    private var viewContext: ModelContext
    
    @ObservationIgnored
    private var rebuildTask: Task<Void, Never>?
    
    //MARK: - Private API - Functions
    
    private func bootStrap() throws {
        try rebuildChannelBundleMap()
    }
    
    /// Schedules a channel map rebuild with debouncing to prevent excessive rebuilds.
    ///
    /// This method cancels any pending rebuild and schedules a new one after a 300ms delay.
    /// The delay is particularly useful for search term changes where users are actively typing.
    private func scheduleChannelBundleMapRebuild() async {
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
                try rebuildChannelBundleMap()
            } catch {
                logError("Failed to rebuild channel map: \(error)")
            }
        }
    }
    
    private func rebuildChannelBundleMap() throws {
        
        let context = self.viewContext
        
        if context.hasChanges {
            logWarning("Unsaved changes prior to building channel map, saving...")
            try context.save()
        }
        
        logDebug("Building Channel Map... 🇺🇸")
        
        var channelsDescriptor: FetchDescriptor<Channel> = FetchDescriptor<Channel>(
            sortBy: [SortDescriptor(\Channel.sortHint, order: .forward)]
        )
        
        let predicate: Predicate<Channel> = Self.predicateBuilder(showFavoritesOnly: showFavoritesOnly,
                                                                  searchTerm: searchTerm,
                                                                  countryCode: selectedCountry,
                                                                  categoryId: selectedCategory)
        
        channelsDescriptor.predicate = predicate
        
        let channels: [Channel] = try context.fetch(channelsDescriptor)
        let map: [ChannelId] = channels.map { $0.id }
        
        self.channelBundleMap = ChannelBundleMap(id: UserDefaults.selectedChannelBundle, map: map)
        
        logDebug("Channel map built.  Total Channels: \(map.count) 🏁")
    }
}
