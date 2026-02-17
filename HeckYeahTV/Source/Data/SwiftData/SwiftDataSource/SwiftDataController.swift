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
final class SwiftDataController: SwiftDataProvider {

    //MARK: - SwiftDataController lifecycle
    
    deinit {
        rebuildTask?.cancel()
        didSaveObserverTask?.cancel()
        selectedBundleObserverTask?.cancel()
    }
    
    init() {
        let stack = SwiftDataStack.shared
        self.viewContext = stack.viewContext
        self.container = stack.container
        
        self.bootStrap()
    }
    
    //MARK: - Internal API - ChannelSourceable protocol implementation

    private(set) var channelBundleMap: ChannelBundleMap = ChannelBundleMap(channelBundleId: "", map: [:], channelIds: [])

    func totalChannelCount() throws -> Int {
        let descriptor = FetchDescriptor<Channel>()
        let totalChannelCount = try viewContext.fetchCount(descriptor)
        return totalChannelCount
    }

    func totalChannelCountFor(deviceId: HDHomeRunDeviceId) throws -> Int {
        let predicate = #Predicate<Channel> { $0.deviceId == deviceId }
        let fetchDescriptor = FetchDescriptor<Channel>(predicate: predicate)
        let count: Int = try viewContext.fetchCount(fetchDescriptor)
        return count
    }

    func homeRunDevices() throws -> [HomeRunDevice] {
        let sort = [SortDescriptor<HomeRunDevice>(\.friendlyName, order: .forward)]
        let fetchDescriptor = FetchDescriptor<HomeRunDevice>(sortBy: sort)
        let devices = try viewContext.fetch(fetchDescriptor)
        return devices
    }
    
    func countries() throws -> [Country] {
        let sort = [SortDescriptor<Country>(\.name, order: .forward)]
        let fetchDescriptor = FetchDescriptor<Country>(sortBy: sort)
        let models = try viewContext.fetch(fetchDescriptor)
        return models
    }
    
    func programCategories() throws -> [ProgramCategory] {
        let sort = [SortDescriptor<ProgramCategory>(\.name, order: .forward)]
        let fetchDescriptor = FetchDescriptor<ProgramCategory>(sortBy: sort)
        let models = try viewContext.fetch(fetchDescriptor)
        return models
    }
    
    func channel(for channelId: ChannelId) throws -> Channel {
        let predicate = #Predicate<Channel> { $0.id == channelId }
        var fetchDescriptor = FetchDescriptor<Channel>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        guard let _program = try viewContext.fetch(fetchDescriptor).first else {
            throw GuideStoreError.noChannelFoundForId(channelId)
        }
        return _program
    }
    
    func channelsForCurrentFilter() throws -> [Channel] {
        let predicate = Self.predicateBuilder(searchTerm: self.searchTerm,
                                              countryCode: self.selectedCountry,
                                              categoryId: self.selectedCategory)
        let sortDescriptor = [SortDescriptor<Channel>(\.sortHint, order: .forward)]
        let fetchDescriptor = FetchDescriptor<Channel>(predicate: predicate, sortBy: sortDescriptor)
        let _channels = try viewContext.fetch(fetchDescriptor)
        return _channels
    }
    
    func channelBundles() throws -> [ChannelBundle] {
        let sortDescriptor = [SortDescriptor<ChannelBundle>(\.name, order: .forward)]
        let fetchDescriptor = FetchDescriptor<ChannelBundle>(sortBy: sortDescriptor)
        let models = try viewContext.fetch(fetchDescriptor)
        return models
    }
    
    func channelBundle(for bundleId: ChannelBundleId) throws -> ChannelBundle {
        let predicate = #Predicate<ChannelBundle> { $0.id == bundleId }
        var fetchDescriptor = FetchDescriptor<ChannelBundle>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        guard let model = try viewContext.fetch(fetchDescriptor).first else {
            throw GuideStoreError.noChannelBundleFoundForId(bundleId)
        }
        return model
    }
    
    func bundleEntry(for bundleEntryId: BundleEntryId?) -> BundleEntry? {
        guard let bundleEntryId else { return nil }
        let predicate = #Predicate<BundleEntry> { $0.id == bundleEntryId }
        var fetchDescriptor = FetchDescriptor<BundleEntry>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        let bundleEntry: BundleEntry? = try? viewContext.fetch(fetchDescriptor).first
        return bundleEntry
    }
    
    func bundleEntry(for channelId: ChannelId?, channelBundleId: ChannelBundleId) -> BundleEntry? {
        guard let channelId else { return nil }
        let predicate = #Predicate<BundleEntry> { $0.channel?.id == channelId && $0.channelBundle.id == channelBundleId }
        var fetchDescriptor = FetchDescriptor<BundleEntry>(predicate: predicate)
        fetchDescriptor.fetchLimit = 1
        let bundleEntry: BundleEntry? = try? viewContext.fetch(fetchDescriptor).first
        return bundleEntry
    }
    
    func isFavorite(channelId: ChannelId?, channelBundleId: ChannelBundleId) -> Bool {
        guard let channelId else { return false }
        let bundleEntry = bundleEntry(for: channelId, channelBundleId: channelBundleId)
        return bundleEntry?.isFavorite ?? false
    }
    
    func toggleIsFavorite(channelId: ChannelId?, channelBundleId: ChannelBundleId) {
        guard let channelId else { return }
        let bundleEntry = bundleEntry(for: channelId, channelBundleId: channelBundleId)
        bundleEntry?.isFavorite.toggle()

        do {
            try viewContext.saveChangesIfNeeded()
        } catch {
            logError("Failed to save favorite toggle for channelId: \(channelId). Error: \(error)")
        }
    }
    
    func invalidateChannelBundleMap() {
        scheduleChannelBundleMapRebuild()
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
    
    func deletePastChannelPrograms() throws {
        // delete - programs that have passed
        logDebug("Deleting program data for programs that ended more than now.")
        let now = Date()
        let oldProgramsPredicate = #Predicate<ChannelProgram> { program in
            program.endTime < now
        }
        try viewContext.delete(model: ChannelProgram.self, where: oldProgramsPredicate)
        try viewContext.saveChangesIfNeeded()
    }
    
    static func predicateBuilder(searchTerm: String?,
                                 countryCode: CountryCodeId,
                                 categoryId: CategoryId?) -> Predicate<Channel> {
        
        var conditions: [Predicate<Channel>] = []

        // Country predicate is always applied but we use "ANY" support local LAN tuners.  These should be returned regardless of current country selection.
        // If you want to filter LAN channels out use .source and the ChannelSourceType enum.
        conditions.append( #Predicate<Channel> { $0.country == countryCode || $0.country == "ANY" })
        
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
    
    //MARK: - Internal API - ChannelFilterable protocol implementation Properties
    
    /// Only show the good channels. Life's too short for the rest.
    var showFavoritesOnly: Bool {
        get {
            access(keyPath: \.showFavoritesOnly)
            return UserDefaults.showFavoritesOnly
        }
        set {
            if showFavoritesOnly != newValue {
                scheduleChannelBundleMapRebuild()
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
                scheduleChannelBundleMapRebuild()
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
                scheduleChannelBundleMapRebuild()
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
            scheduleChannelBundleMapRebuild()
        }
    }
    
    //MARK: - Internal API - SwiftDataProvider protocol Implementation
    
    @ObservationIgnored
    var viewContext: ModelContext
    
    @ObservationIgnored
    var container: ModelContainer
    
    //MARK: - Private API Properties
    
    @ObservationIgnored
    private var rebuildTask: Task<Void, Never>?
    
    @ObservationIgnored
    private var didSaveObserverTask: Task<Void, Never>?

    @ObservationIgnored
    private var selectedBundleObserverTask: Task<Void, Never>?
    
    //MARK: - Private API - Functions
    
    private func bootStrap() {
        do {
            try rebuildChannelBundleMap()
        } catch {
            logError("Failed to build initial channel map: \(error)")
        }
        observeContextDidSave()
        observeSelectedChannelBundle()
    }
    
    /// Rebuilds the channel map whenever the view context saves, catches bundle channel membership changes
    /// (channels added/removed from a bundle) that wouldn't be caught by filter property changes.
    private func observeContextDidSave() {
        didSaveObserverTask = Task { @MainActor in
            let notifications = NotificationCenter.default.notifications(named: ModelContext.didSave)
            for await notification in notifications {
                guard !Task.isCancelled else { return }
                // -- Filter to the viewContext only. --
                // Background importer contexts also post this notification and we
                // don't want their saves triggering a map rebuild.
                guard (notification.object as? ModelContext) === self.viewContext else { continue }
                logDebug("Main Context did save detected.")
                self.scheduleChannelBundleMapRebuild()
            }
        }
    }

    /// Rebuilds the channel map whenever the active channel bundle selection changes.
    private func observeSelectedChannelBundle() {
        selectedBundleObserverTask = Task { @MainActor in
            let appState: AppStateProvider = InjectedValues[\.sharedAppState]
            var lastBundleId = appState.selectedChannelBundleId
            while !Task.isCancelled {
                await withCheckedContinuation { continuation in
                    withObservationTracking {
                        _ = appState.selectedChannelBundleId
                    } onChange: {
                        continuation.resume()
                    }
                }
                guard !Task.isCancelled else { return }
                let newBundleId = appState.selectedChannelBundleId
                if newBundleId != lastBundleId {
                    lastBundleId = newBundleId
                    self.scheduleChannelBundleMapRebuild()
                }
            }
        }
    }

    /// Schedules a channel map rebuild with debouncing to prevent excessive rebuilds.
    ///
    /// This method cancels any pending rebuild and schedules a new one after a 300ms delay.
    private func scheduleChannelBundleMapRebuild() {
        // Cancel any existing rebuild task
        rebuildTask?.cancel()
        
        // Schedule a new rebuild after debounce delay
        rebuildTask = Task { @MainActor in
            // Wait for debounce period
            try? await Task.sleep(for: .milliseconds(300))
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
        
        let appState: AppStateProvider = InjectedValues[\.sharedAppState]
        let channelBundleId = appState.selectedChannelBundleId
        
        var conditions: [Predicate<BundleEntry>] = []
        conditions.append( #Predicate<BundleEntry> { bundleEntry in
            bundleEntry.channelBundle.id == channelBundleId &&
            bundleEntry.channel != nil
        } )
        if showFavoritesOnly {
            conditions.append(#Predicate<BundleEntry> { $0.isFavorite == true })
        }
        let compoundPredicate = conditions.reduce(#Predicate { _ in true }) { current, next in
            #Predicate { current.evaluate($0) && next.evaluate($0) }
        }
        let sortDescriptor: [SortDescriptor] = [SortDescriptor(\BundleEntry.sortHint, order: .forward)]
        let channelsDescriptor = FetchDescriptor<BundleEntry>(predicate: compoundPredicate, sortBy: sortDescriptor)
        let bundleEntries: [BundleEntry] = (try context.fetch(channelsDescriptor)).filter({ $0.channel != nil})
        
        let channelIds = bundleEntries.map { $0.channel!.id }
        let map: ChannelMap =  bundleEntries.reduce(into: [:]) { result, item in
            // Note: Can force unwrap channelId here because of the filtering above.
            result[item.channel!.id] = item.id
        }
        
        channelBundleMap = ChannelBundleMap(channelBundleId: channelBundleId,
                                            map: map,
                                            channelIds: channelIds)
        
        logDebug("Channel map built.  Total Channels: \(channelBundleMap.mapCount) 🏁")
    }
}
