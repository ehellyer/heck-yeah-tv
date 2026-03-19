//
//  BaseSwiftDataController.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData
import Observation

@MainActor @Observable
class BaseSwiftDataController: SwiftDataProvider {

    //MARK: - BaseSwiftDataController lifecycle
    
    deinit {
        rebuildTask?.cancel()
        didSaveObserverTask?.cancel()
        selectedBundleObserverTask?.cancel()
    }
    
    init(viewContext: ModelContext, container: ModelContainer) {
        self.viewContext = viewContext
        self.container = container
        self.bootStrap()
    }
    
    //MARK: - Internal API - ChannelManageable protocol implementation

    private var _cachedSelectedChannel: Channel?
    
    /// The currently selected channel that should be played on app launch.
    var selectedChannel: Channel? {
        get {
            access(keyPath: \.selectedChannel)
            do {
                guard _cachedSelectedChannel == nil else { return _cachedSelectedChannel }
                let sortDescriptor = SortDescriptor<SelectedChannel>(\.dateAdded, order: .reverse)
                var fetchDescriptor = FetchDescriptor<SelectedChannel>(sortBy: [sortDescriptor])
                fetchDescriptor.fetchLimit = 1
                let selectedChannel = try viewContext.fetch(fetchDescriptor).first
                _cachedSelectedChannel = selectedChannel?.channel
                return selectedChannel?.channel
            } catch {
                logError("Failed to fetch selectedChannel: \(error)")
            }
            return nil
        }
        set {
            withMutation(keyPath: \.selectedChannel) {
                do {
                    //Cache the selected channel to prevent repeated reads on get {}
                    _cachedSelectedChannel = newValue
                    if let channel = newValue {
                        addRecentlyViewedChannel(channel: channel)
                        let selectedChannel = SelectedChannel(channel: channel)
                        viewContext.insert(selectedChannel)
                        try viewContext.saveChangesIfNeeded()
                    }
                    cleanupOldSelectedChannels()
                } catch {
                    logError("Failed to save selectedChannel: \(error)")
                }
            }
        }
    }
    
    private(set) var channelBundleMap: ChannelBundleMap = ChannelBundleMap(channelBundleId: "", map: [:], channelIds: [])

    func totalIPChannelCatalogCount() -> Int {
        do {
            let iptvDeviceId = IPTVImporter.iptvDeviceId
            let predicate = #Predicate<Channel> { $0.deviceId == iptvDeviceId }
            let descriptor = FetchDescriptor<Channel>(predicate: predicate)
            let totalChannelCount = try viewContext.fetchCount(descriptor)
            return totalChannelCount
        } catch {
            logError("Unable to determine total channel count (IPTV channels + HDHomeRun channels. Error: \(error)")
            return 0
        }
    }
    
    func combinedCountFor(bundleId: ChannelBundleId) -> Int {
        do {
            let deviceIds = try devices(enabledState: true)
            let predicate = #Predicate<Channel> { channel in
                deviceIds.contains(channel.deviceId)
            }
            let descriptor = FetchDescriptor<Channel>(predicate: predicate)
            let tunerChannelCount = try viewContext.fetchCount(descriptor)
            
            let bundleChannelCount = channelCountFor(bundleId: bundleId)

            return tunerChannelCount + bundleChannelCount
        } catch {
            logError("Unable to determine total channel count (IPTV channels + HDHomeRun channels. Error: \(error)")
            return 0
        }
    }
    
    func channelCountFor(bundleId: ChannelBundleId) -> Int {
        do {
            let deviceId = IPTVImporter.iptvDeviceId
            let predicate = #Predicate<BundleEntry> { bundleEntry in
                bundleEntry.channelBundle.id == bundleId && bundleEntry.channel?.deviceId == deviceId
            }
            let descriptor = FetchDescriptor<BundleEntry>(predicate: predicate)
            let count = try viewContext.fetchCount(descriptor)
            return count
        } catch {
            logError("Unable to determine channel count for bundleId: \(bundleId) Error: \(error)")
            return 0
        }
    }

    func channelCountFor(deviceId: HDHomeRunDeviceId) -> Int {
        do {
            let predicate = #Predicate<Channel> { $0.deviceId == deviceId }
            let fetchDescriptor = FetchDescriptor<Channel>(predicate: predicate)
            let count: Int = try viewContext.fetchCount(fetchDescriptor)
            return count
        } catch {
            logError("Unable to determine total channel count for HDHomeRun device. Error: \(error)")
            return 0
        }
    }

    func homeRunDevices() -> [HomeRunDevice] {
        do {
            let sort = [SortDescriptor<HomeRunDevice>(\.friendlyName, order: .forward)]
            let fetchDescriptor = FetchDescriptor<HomeRunDevice>(sortBy: sort)
            let devices = try viewContext.fetch(fetchDescriptor)
            return devices
        } catch {
            logError("Unable to fetch HDHomeRunDevice(s). Error: \(error)")
            return []
        }
    }
    
    func toggleDeviceChannelLineupInclusion(device: HomeRunDevice) {
        do {
            device.isEnabled.toggle()
            try viewContext.saveChangesIfNeeded()
        } catch {
            logError("Unable to toggle HDHomeRunDevice isEnabled property. Error: \(error)")
        }
    }
    
    func countries() -> [Country] {
        do {
            let sort = [SortDescriptor<Country>(\.name, order: .forward)]
            let fetchDescriptor = FetchDescriptor<Country>(sortBy: sort)
            let models = try viewContext.fetch(fetchDescriptor)
            return models
        } catch {
            logError("Unable to fetch countries. Error: \(error)")
            return []
        }
    }
    
    func programCategories() -> [ProgramCategory] {
        do {
            let sort = [SortDescriptor<ProgramCategory>(\.name, order: .forward)]
            let fetchDescriptor = FetchDescriptor<ProgramCategory>(sortBy: sort)
            let models = try viewContext.fetch(fetchDescriptor)
            return models
        } catch {
            logError("Unable to fetch program categories. Error: \(error)")
            return []
        }
    }
    
    func channel(for channelId: ChannelId) -> Channel? {
        do {
            let predicate = #Predicate<Channel> { $0.id == channelId }
            var fetchDescriptor = FetchDescriptor<Channel>(predicate: predicate)
            fetchDescriptor.fetchLimit = 1
            guard let _program = try viewContext.fetch(fetchDescriptor).first else {
                throw GuideStoreError.noChannelFoundForId(channelId)
            }
            return _program
        } catch {
            logError("Unable to fetch channel for channelId: \(channelId). Error: \(error)")
            return nil
        }
    }
    
    func channelsForCurrentFilter() -> [Channel] {
        do {
            let predicate = Self.predicateBuilder(searchTerm: self.searchTerm,
                                                  countryCode: self.selectedCountry,
                                                  categoryId: self.selectedCategory)
            let sortDescriptor = [SortDescriptor<Channel>(\.sortHint, order: .forward)]
            let fetchDescriptor = FetchDescriptor<Channel>(predicate: predicate, sortBy: sortDescriptor)
            let _channels = try viewContext.fetch(fetchDescriptor)
            return _channels
        } catch {
            logError("Unable to fetch channels for current filter. searchTerm: \"\(searchTerm ?? "nil")\" countryCode: \"\(selectedCountry)\" categoryId: \"\(selectedCategory ?? "nil")\"  . Error: \(error)")
            return []
        }
    }
    
    func channelBundles() -> [ChannelBundle] {
        do {
            let sortDescriptor = [SortDescriptor<ChannelBundle>(\.name, order: .forward)]
            let fetchDescriptor = FetchDescriptor<ChannelBundle>(sortBy: sortDescriptor)
            let models = try viewContext.fetch(fetchDescriptor)
            return models
        } catch {
            logError("Unable to fetch channel bundles. Error: \(error)")
            return []
        }
    }
    
    func addChannelBundle(name: String) -> ChannelBundle? {
        do {
            let newBundle = ChannelBundle(id: UUID().uuidString,
                                          name: name,
                                          channels: [])
            viewContext.insert(newBundle)
            try updateChannelBundleWithIncludedChannels()
            try viewContext.saveChangesIfNeeded()
            return newBundle
        } catch {
            logError("Unable to create new channel bundle: \(name). Error: \(error)")
            return nil
        }
    }
    
    func channelBundle(for bundleId: ChannelBundleId) -> ChannelBundle? {
        do {
            let predicate = #Predicate<ChannelBundle> { $0.id == bundleId }
            var fetchDescriptor = FetchDescriptor<ChannelBundle>(predicate: predicate)
            fetchDescriptor.fetchLimit = 1
            guard let model = try viewContext.fetch(fetchDescriptor).first else {
                throw GuideStoreError.noChannelBundleFoundForId(bundleId)
            }
            return model
        } catch {
            logError("Unable to fetch channel bundle for channelBundleId: \(bundleId). Error: \(error)")
            return nil
        }
    }
    
    func bundleEntry(for bundleEntryId: BundleEntryId?) -> BundleEntry? {
        guard let bundleEntryId else { return nil }
        do {
            let predicate = #Predicate<BundleEntry> { $0.id == bundleEntryId }
            var fetchDescriptor = FetchDescriptor<BundleEntry>(predicate: predicate)
            fetchDescriptor.fetchLimit = 1
            let bundleEntry: BundleEntry? = try viewContext.fetch(fetchDescriptor).first
            return bundleEntry
        } catch {
            logError("Unable to fetch BundleEntry for bundleEntryId: \(bundleEntryId). Error: \(error)")
            return nil
        }
    }
    
    func bundleEntry(for channelId: ChannelId?, channelBundleId: ChannelBundleId) -> BundleEntry? {
        guard let channelId else { return nil }
        do {
            let predicate = #Predicate<BundleEntry> { $0.channel?.id == channelId && $0.channelBundle.id == channelBundleId }
            var fetchDescriptor = FetchDescriptor<BundleEntry>(predicate: predicate)
            fetchDescriptor.fetchLimit = 1
            let bundleEntry: BundleEntry? = try viewContext.fetch(fetchDescriptor).first
            return bundleEntry
        } catch {
            logError("Unable to fetch BundleEntry for channelId: \(channelId), channelBundleId: \(channelBundleId). Error: \(error)")
            return nil
        }
    }
    
    func isFavorite(channelId: ChannelId?, channelBundleId: ChannelBundleId) -> Bool {
        guard let channelId else { return false }
        let bundleEntry = bundleEntry(for: channelId, channelBundleId: channelBundleId)
        return bundleEntry?.isFavorite ?? false
    }
    
    func toggleIsFavorite(channelId: ChannelId?, channelBundleId: ChannelBundleId) {
        guard let channelId else { return }
        do {
            let bundleEntry = bundleEntry(for: channelId, channelBundleId: channelBundleId)
            bundleEntry?.isFavorite.toggle()
            try viewContext.saveChangesIfNeeded()
        } catch {
            logError("Failed to save favorite toggle for channelId: \(channelId), channelBundleId: \(channelBundleId). Error: \(error)")
        }
    }
    
    func invalidateChannelBundleMap() {
        scheduleChannelBundleMapRebuild()
    }
    
    func invalidateTunerLineUp() {
        do {
            try updateChannelBundleWithIncludedChannels()
        } catch {
            logError("Failed to synchronize tuner device channel lineup with all channel bundles.")
        }
        
    }
    
    func channelPrograms(for channelId: ChannelId) -> [ChannelProgram] {
        do {
            let predicate = #Predicate<ChannelProgram> { $0.channelId == channelId }
            let startTimeSort = SortDescriptor<ChannelProgram>(\.startTime, order: .forward)
            let fetchDescriptor = FetchDescriptor<ChannelProgram>(predicate: predicate, sortBy: [startTimeSort])
            let _programs = try viewContext.fetch(fetchDescriptor)
            return _programs
        } catch {
            logError("Failed to fetch channel programs for channelId: \(channelId).  Error \(error)")
            return []
        }
    }
    
    func deletePastChannelPrograms() {
        guard not(PreviewDetector.isRunningInPreview) else { return }
        do {
            logDebug("Deleting program data for programs that ended more than now.")
            let now = Date()
            let oldProgramsPredicate = #Predicate<ChannelProgram> { program in
                program.endTime < now
            }
            try viewContext.delete(model: ChannelProgram.self, where: oldProgramsPredicate)
            try viewContext.saveChangesIfNeeded()
        } catch {
            logError("Failed to delete past channel programs.  Error \(error)")
        }
    }
    
    func addRecentlyViewedChannel(channel: Channel) {
        let recentlyViewed = RecentlyViewedChannel(channel: channel, viewedAt: Date())
        viewContext.insert(recentlyViewed)
        // Cleanup old entries if we've exceeded the max count
        cleanupOldRecentlyViewedChannels(maxCount: 5000)
    }
    
    
    func recentlyViewDescriptor(limit: Int = 10) -> FetchDescriptor<RecentlyViewedChannel> {
        let viewedAtSort = SortDescriptor<RecentlyViewedChannel>(\.viewedAt, order: .reverse)
        var fetchDescriptor = FetchDescriptor<RecentlyViewedChannel>(sortBy: [viewedAtSort])
        fetchDescriptor.fetchLimit = limit
        return fetchDescriptor
    }
    
    func recentlyViewedChannels(limit: Int = 10) -> [RecentlyViewedChannel] {
        do {
            let fetchDescriptor = recentlyViewDescriptor(limit: limit)
            let recentChannels = try viewContext.fetch(fetchDescriptor)
            return recentChannels
        } catch {
            logError("Failed to fetch recently viewed channels. Error: \(error)")
            return []
        }
    }
    
    func cleanupOldRecentlyViewedChannels(maxCount: Int = 5000) {
        do {
            // Fetch all entries sorted by viewedAt (oldest first)
            let viewedAtSort = SortDescriptor<RecentlyViewedChannel>(\.viewedAt, order: .reverse)
            let fetchDescriptor = FetchDescriptor<RecentlyViewedChannel>(sortBy: [viewedAtSort])
            let allEntries = try viewContext.fetch(fetchDescriptor)
            
            // Calculate how many to delete
            let entryCount = allEntries.count
            let deleteCount = entryCount - maxCount
            
            guard deleteCount > 0 else {
                logDebug("There are \(entryCount) RecentlyViewedChannel entries.  We are not at max count, therefore nothing to delete.")
                return
            }
                
            for entry in allEntries.suffix(from: maxCount) {
                viewContext.delete(entry)
            }
            
            try viewContext.saveChangesIfNeeded()
            logDebug("Cleaned up \(deleteCount) old RecentlyViewedChannel entries.")
        } catch {
            logError("Failed to cleanup old RecentlyViewedChannel entries. Error: \(error)")
        }
    }

    func cleanupOldSelectedChannels(maxCount: Int = 5000) {
        do {
            // Fetch all entries sorted by viewedAt (oldest first)
            let sortDescriptor = SortDescriptor<SelectedChannel>(\.dateAdded, order: .reverse)
            let fetchDescriptor = FetchDescriptor<SelectedChannel>(sortBy: [sortDescriptor])
            let allEntries = try viewContext.fetch(fetchDescriptor)
            
            // Calculate how many to delete
            let entryCount = allEntries.count
            let deleteCount = entryCount - maxCount
            
            guard deleteCount > 0 else {
                logDebug("There are \(entryCount) SelectedChannel entries.  We are not at max count, therefore nothing to delete.")
                return
            }
            
            for entry in allEntries.suffix(from: maxCount) {
                viewContext.delete(entry)
            }
            
            try viewContext.saveChangesIfNeeded()
            logDebug("Cleaned up \(deleteCount) old SelectedChannel entries.")
        } catch {
            logError("Failed to cleanup old SelectedChannel entries. Error: \(error)")
        }
    }
    
    static func predicateBuilder(searchTerm: String?,
                                 countryCode: CountryCodeId,
                                 categoryId: CategoryId?) -> Predicate<Channel> {
        
        let deviceId = IPTVImporter.iptvDeviceId
        var conditions: [Predicate<Channel>] = []
        conditions.append( #Predicate<Channel> { $0.country == countryCode && $0.deviceId == deviceId })
        
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
    
    private var _searchTerm: String? = nil
    
    /// Filter by channel title search term. Because scrolling through 10,000 channels wasn't tedious enough.
    var searchTerm: String? {
        get {
            return _searchTerm
        }
        set {
            guard newValue != _searchTerm else { return }
            _searchTerm = newValue.map { String($0.prefix(35)) }
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
                    try? self.updateChannelBundleWithIncludedChannels()
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
    
    private func devices(enabledState: Bool) throws -> [HDHomeRunDeviceId] {
        let predicate = #Predicate<HomeRunDevice> { $0.isEnabled == enabledState }
        var descriptor = FetchDescriptor<HomeRunDevice>(predicate: predicate)
        descriptor.propertiesToFetch = [\.deviceId]
        let devices = try viewContext.fetch(descriptor)
        let deviceIds = devices.map { $0.deviceId }
        return deviceIds
    }
    
    private func channelsFor(deviceIds: [HDHomeRunDeviceId]) throws -> [Channel] {
        guard not(deviceIds.isEmpty) else { return [] }
        let channelPredicate = #Predicate<Channel> { channel in
            deviceIds.contains(channel.deviceId)
        }
        let channelDescriptor = FetchDescriptor<Channel>(predicate: channelPredicate)
        do {
            let channels = try viewContext.fetch(channelDescriptor)
            return channels
        } catch {
            logError("Error fetching channels for deviceId(s) \(deviceIds).  Error: \(error)")
            throw error
        }
    }
    
    private func updateChannelBundleWithIncludedChannels() throws {
        logDebug("Starting sync task for device(s) channel lineup... 🇺🇸")
        
        // Fetch all channel bundles
        let bundleDescriptor = FetchDescriptor<ChannelBundle>()
        let allChannelBundles = try viewContext.fetch(bundleDescriptor)
        
        guard !allChannelBundles.isEmpty else {
            return
        }
        
        // Get enabled and disabled device IDs
        let enabledDeviceIds = try devices(enabledState: true)
        let disabledDeviceIds = try devices(enabledState: false)
        
        // Fetch channels for enabled devices (to add)
        let channelsToAdd = try channelsFor(deviceIds: enabledDeviceIds)
        
        // Fetch channels for disabled devices (to remove)
        let channelsToRemove = try channelsFor(deviceIds: disabledDeviceIds)
        
        // Add and remove entries
        try addBundleEntries(for: channelsToAdd, across: allChannelBundles)
        try removeBundleEntries(for: channelsToRemove, across: allChannelBundles)
        
        try viewContext.saveChangesIfNeeded()
        
        logDebug("Completed sync task for device(s) channel lineup... 🏁")
    }
    
    private func addBundleEntries(for channels: [Channel], across bundles: [ChannelBundle]) throws {
        guard !channels.isEmpty else { return }
        
        // Compute all expected IDs for enabled channels across all bundles
        var expectedAddIds: [BundleEntryId] = []
        for bundle in bundles {
            for channel in channels {
                expectedAddIds.append(BundleEntry.newBundleEntryId(channelBundleId: bundle.id, channelId: channel.id))
            }
        }
        
        // Fetch existing entries for these IDs
        let addEntryPredicate = #Predicate<BundleEntry> { entry in
            expectedAddIds.contains(entry.id)
        }
        let addEntryDescriptor = FetchDescriptor<BundleEntry>(predicate: addEntryPredicate)
        let existingAddEntries = try viewContext.fetch(addEntryDescriptor)
        let existingAddIds = Set(existingAddEntries.map { $0.id })
        
        // Insert missing entries
        for bundle in bundles {
            for channel in channels {
                let bundleEntryId = BundleEntry.newBundleEntryId(channelBundleId: bundle.id, channelId: channel.id)
                
                if !existingAddIds.contains(bundleEntryId) {
                    let newEntry = BundleEntry(channel: channel,
                                               channelBundle: bundle,
                                               sortHint: channel.sortHint,
                                               isFavorite: false)
                    viewContext.insert(newEntry)
                }
            }
        }
    }
    
    private func removeBundleEntries(for channels: [Channel], across bundles: [ChannelBundle]) throws {
        guard !channels.isEmpty else { return }
        
        // Compute all IDs to remove across all bundles
        var expectedRemoveIds: [BundleEntryId] = []
        for bundle in bundles {
            for channel in channels {
                expectedRemoveIds.append(BundleEntry.newBundleEntryId(channelBundleId: bundle.id, channelId: channel.id))
            }
        }
        
        // Fetch existing entries to delete
        let removeEntryPredicate = #Predicate<BundleEntry> { entry in
            expectedRemoveIds.contains(entry.id)
        }
        let removeEntryDescriptor = FetchDescriptor<BundleEntry>(predicate: removeEntryPredicate)
        let entriesToRemove = try viewContext.fetch(removeEntryDescriptor)
        
        // Delete them
        for entry in entriesToRemove {
            viewContext.delete(entry)
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
        
        channelBundleMap.update(channelBundleId: channelBundleId,
                                map: map,
                                channelIds: channelIds)
        
        logDebug("Channel map built.  Total Channels: \(channelBundleMap.mapCount) 🏁")
    }
}
