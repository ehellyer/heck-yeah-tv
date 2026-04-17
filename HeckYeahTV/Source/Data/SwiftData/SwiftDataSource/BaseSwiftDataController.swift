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
    
    @ObservationIgnored @Injected(\.analytics) private var analytics
    
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
                        
                        // Log analytics for channel viewing
                        let source: ChannelSource = .guide // Default to guide, could be enhanced to track actual source
                        analytics.log(.channelViewed(channelId: channel.id, channelName: channel.title, source: source))
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
            let fetchDescriptor = ChannelPredicate(deviceIds: [iptvDeviceId]).fetchDescriptorNoSort()
            let count: Int = try viewContext.fetchCount(fetchDescriptor)
            return count
        } catch {
            logError("Unable to determine total channel count (IPTV channels + HDHomeRun channels. Error: \(error)")
            return 0
        }
    }
    
    func channelCountFor(bundleId: ChannelBundleId) -> Int {
        do {
            let deviceId = IPTVImporter.iptvDeviceId
            let descriptor = BundleEntryPredicate(channelBundleId: bundleId, deviceId: deviceId).fetchDescriptorNoSort()
            let count: Int = try viewContext.fetchCount(descriptor)
            return count
        } catch {
            logError("Unable to determine channel count for bundleId: \(bundleId) Error: \(error)")
            return 0
        }
    }
    
    func channelCountFor(deviceId: HDHomeRunDeviceId) -> Int {
        do {
            let fetchDescriptor = ChannelPredicate(deviceIds: [deviceId]).fetchDescriptorNoSort()
            let count: Int = try viewContext.fetchCount(fetchDescriptor)
            return count
        } catch {
            logError("Unable to determine total channel count for HDHomeRun device. Error: \(error)")
            return 0
        }
    }
    
    func homeRunDevices() -> [HomeRunDevice] {
        do {
            let fetchDescriptor = HomeRunDevicePredicate().fetchDescriptor()
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
            var fetchDescriptor = ChannelPredicate(channelId: channelId).fetchDescriptor()
            fetchDescriptor.fetchLimit = 1
            guard let channel = try viewContext.fetch(fetchDescriptor).first else {
                throw GuideStoreError.noChannelFoundForId(channelId)
            }
            return channel
        } catch {
            logError("Unable to fetch channel for channelId: \(channelId). Error: \(error)")
            return nil
        }
    }
    
    func channelsForCurrentFilter() -> [Channel] {
        do {
            let fetchDescriptor = ChannelPredicate(searchTerm: self.searchTerm,
                                                   countryCode: self.selectedCountry,
                                                   categoryId: self.selectedCategory).fetchDescriptor()
            
            let _channels = try viewContext.fetch(fetchDescriptor)
            return _channels
        } catch {
            logError("Unable to fetch channels for current filter. searchTerm: \"\(searchTerm ?? "nil")\" countryCode: \"\(selectedCountry)\" categoryId: \"\(selectedCategory ?? "nil")\"  . Error: \(error)")
            return []
        }
    }
    
    func channelBundles() -> [ChannelBundle] {
        do {
            let fetchDescriptor = ChannelBundlePredicate().fetchDescriptor()
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
            var fetchDescriptor = ChannelBundlePredicate(bundleId: bundleId).fetchDescriptor()
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
            var fetchDescriptor = BundleEntryPredicate(bundleEntryIds: [bundleEntryId]).fetchDescriptor()
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
            var fetchDescriptor = BundleEntryPredicate(channelId: channelId, channelBundleId: channelBundleId).fetchDescriptor()
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
    
    /// Rebuilds the ChannelBundleMap which drives the guide UI lazy loading.
    func invalidateChannelBundleMap() {
        scheduleChannelBundleMapRebuild()
    }
    
    /// An internal function that will add or remove bundle entries from the channel bundles as necessary.
    /// In order for the `BundleEntry` to be added to a `ChannelBundle` the device that has the Channel that the BundleEntry points to must be enabled.  And the ChannelBundle must be associated with the HomeRunDevice
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
    
    // MARK: - Delete / clean up operations
    
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
    
    func cleanupOldRecentlyViewedChannels(maxCount: Int = 5000) {
        do {
            // Fetch all entries sorted by viewedAt (oldest first)
            let viewedAtSort = SortDescriptor<RecentlyViewedChannel>(\.viewedAt, order: .reverse)
            let fetchDescriptor = FetchDescriptor<RecentlyViewedChannel>(sortBy: [viewedAtSort])
            let recentlyViewedChannels = try viewContext.fetch(fetchDescriptor)
            
            // Calculate how many to delete
            let entryCount = recentlyViewedChannels.count
            let deleteCount = entryCount - maxCount
            
            guard deleteCount > 0 else {
                logDebug("There are \(entryCount) RecentlyViewedChannel entries.  We are not at max count, therefore nothing to delete.")
                return
            }
            
            for recentlyViewedChannel in recentlyViewedChannels.suffix(from: maxCount) {
                viewContext.delete(recentlyViewedChannel)
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
            let selectedChannels = try viewContext.fetch(fetchDescriptor)
            
            // Calculate how many to delete
            let entryCount = selectedChannels.count
            let deleteCount = entryCount - maxCount
            
            guard deleteCount > 0 else {
                logDebug("There are \(entryCount) SelectedChannel entries.  We are not at max count, therefore nothing to delete.")
                return
            }
            
            for selectedChannel in selectedChannels.suffix(from: maxCount) {
                viewContext.delete(selectedChannel)
            }
            
            try viewContext.saveChangesIfNeeded()
            logDebug("Cleaned up \(deleteCount) old SelectedChannel entries.")
        } catch {
            logError("Failed to cleanup old SelectedChannel entries. Error: \(error)")
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
    
    func addDeviceToBundle(device: HomeRunDevice, bundle: ChannelBundle) {
        do {
            // Check if already associated
            guard not(bundle.isAssociated(with: device)) else {
                logDebug("Device \(device.friendlyName) is already associated with bundle \(bundle.name)")
                return
            }
            
            // Create the association
            let association = ChannelBundleDevice(bundle: bundle, device: device)
            viewContext.insert(association)
            
            try viewContext.saveChangesIfNeeded()
            logDebug("Added device \(device.friendlyName) to bundle \(bundle.name)")
        } catch {
            logError("Failed to add device to bundle. Error: \(error)")
        }
    }
    
    func removeDeviceFromBundle(device: HomeRunDevice, bundle: ChannelBundle) {
        do {
            // Remove the association
            for association in device.bundleAssociations {
                viewContext.delete(association)
            }
            
            try viewContext.saveChangesIfNeeded()
            logDebug("Removed device \(device.friendlyName) from bundle \(bundle.name)")
        } catch {
            logError("Failed to remove device from bundle. Error: \(error)")
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
                
                // Check if the save contains changes that affect the channel bundle map
                if self.shouldRebuildMapForSave(notification: notification) {
                    logDebug("Main Context did save detected with relevant changes - scheduling rebuild.")
                    self.scheduleChannelBundleMapRebuild()
                } else {
                    logDebug("Main Context did save detected but no relevant changes - skipping rebuild.")
                }
            }
        }
    }
    
    /// Determines if a save notification contains changes that require rebuilding the channel bundle map.
    ///
    /// Only changes to these models affect the guide UI and require a rebuild:
    /// - `Channel`: new channels, deletions, property changes
    /// - `ChannelBundle`: bundle creation, deletion, modification
    /// - `BundleEntry`: channels added/removed, favorite toggles
    /// - `ChannelBundleDevice`: device-to-bundle associations
    /// - `HomeRunDevice`: enabled/disabled state changes
    ///
    /// Changes to these models are ignored:
    /// - `SelectedChannel`: tracks current playback only
    /// - `RecentlyViewedChannel`: view history only
    /// - `ChannelProgram`: guide data, doesn't affect channel list
    ///
    /// - Parameter notification: The `ModelContext.didSave` notification
    /// - Returns: `true` if the map should be rebuilt, `false` otherwise
    private func shouldRebuildMapForSave(notification: Notification) -> Bool {
        // Get the changed objects - SwiftData provides these as arrays of identifiers
        let dataChanges = notification.dataChanges
        
        // Combine all changes
        let allChangedIDs = dataChanges.inserted.union(dataChanges.updated).union(dataChanges.deleted)
        
        // Check if any of the changed objects are types that affect the channel bundle map
        for identifier in allChangedIDs {
            let entityName = identifier.entityName
            
            // Types that require a rebuild
            if entityName == String(describing: Channel.self) ||
               entityName == String(describing: ChannelBundle.self) ||
               entityName == String(describing: BundleEntry.self) ||
               entityName == String(describing: ChannelBundleDevice.self) ||
               entityName == String(describing: HomeRunDevice.self) {
                return true
            }
        }
        
        // No relevant changes found
        return false
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
    
    private func offlineDeviceIds() -> [HDHomeRunDeviceId] {
        do {
            var descriptor = HomeRunDevicePredicate(isOffline: true).fetchDescriptor()
            descriptor.propertiesToFetch = [\.deviceId]
            let devices = try viewContext.fetch(descriptor)
            let deviceIds = devices.map { $0.deviceId }
            return deviceIds
        } catch {
            logError("Failed to return offline deviceIds from SwiftData.  Error: \(error)")
            return []
        }
    }
    
    private func devices(enabledState: Bool) throws -> [HDHomeRunDeviceId] {
        var descriptor = HomeRunDevicePredicate(isEnabled: enabledState).fetchDescriptor()
        descriptor.propertiesToFetch = [\.deviceId]
        let devices = try viewContext.fetch(descriptor)
        let deviceIds = devices.map { $0.deviceId }
        return deviceIds
    }
    
    private func channelsFor(deviceIds: [HDHomeRunDeviceId]) throws -> [Channel] {
        guard not(deviceIds.isEmpty) else { return [] }
        let fetchDescriptor = ChannelPredicate(deviceIds: deviceIds).fetchDescriptor()
        do {
            let channels = try viewContext.fetch(fetchDescriptor)
            return channels
        } catch {
            logError("Error fetching channels for deviceId(s) \(deviceIds).  Error: \(error)")
            throw error
        }
    }
    
    private func deviceChannelBundles() -> [ChannelBundleDevice] {
        do {
            let bundleDeviceDescriptor = FetchDescriptor<ChannelBundleDevice>()
            let bundleDevices = try viewContext.fetch(bundleDeviceDescriptor)
            return bundleDevices
        } catch {
            logError("Unable to fetch channel bundle devices. [ChannelBundleDevice].  Error: \(error)")
        }
        return []
    }
    
    /// Synchronize the `BundleEntry`(s) in the `ChannelBundle`(s) based on the `HomeRunDevice` enabled state and if the device is associated to the channel bundle.
    private func updateChannelBundleWithIncludedChannels() throws {
        logDebug("Starting sync task for device(s) channel lineup... 🇺🇸")
        
        // Fetch all channel bundles
        let allBundles = channelBundles()
        
        // Process each bundle individually
        for bundle in allBundles {
            // Get enabled devices associated with this bundle
            let enabledChannelBundleDeviceIds = bundle.deviceAssociations
                .map { $0.device }
                .filter { $0.isEnabled }
                .map { $0.deviceId }
            
            let disabledChannelBundleDevices = bundle.deviceAssociations
                .filter { $0.device.isEnabled == false }
            
            disabledChannelBundleDevices.forEach { channelBundleDevice in
                self.viewContext.delete(channelBundleDevice)
            }
            
            // Get channels for the enabled devices associated with this bundle
            let channelsToAdd = try channelsFor(deviceIds: enabledChannelBundleDeviceIds)
            
            // Determine which channels should be removed from this bundle
            // Remove if: device is disabled OR device is enabled but NOT associated with this bundle
            let channelsToRemove = try channelsToRemoveFrom(bundle: bundle)
            
            // Add and remove entries for this specific bundle
            try addBundleEntries(for: channelsToAdd, to: bundle)
            try removeBundleEntries(for: channelsToRemove, from: bundle)
        }
        
        try viewContext.saveChangesIfNeeded()
        
        logDebug("Completed sync task for device(s) channel lineup... 🏁")
    }
    
    /// Returns channels that should be removed from a bundle
    /// (channels from disabled devices OR channels from enabled devices not associated with the bundle)
    private func channelsToRemoveFrom(bundle: ChannelBundle) throws -> [Channel] {
        // Get all HDHomeRun device IDs associated with this bundle (enabled or not)
        let associatedDeviceIds = Set(bundle.deviceAssociations.map { $0.device.deviceId })
        
        // Get all enabled device IDs that are NOT associated with this bundle
        let allEnabledDeviceIds = try devices(enabledState: true)
        let enabledButNotAssociated = allEnabledDeviceIds.filter { !associatedDeviceIds.contains($0) }
        
        // Get all disabled device IDs
        let allDisabledDeviceIds = try devices(enabledState: false)
        
        // Combine: disabled devices + enabled but not associated devices
        let deviceIdsToRemove = enabledButNotAssociated + allDisabledDeviceIds
        
        // Get channels for these devices
        return try channelsFor(deviceIds: deviceIdsToRemove)
    }
    
    private func addBundleEntries(for channels: [Channel], to bundle: ChannelBundle) throws {
        guard !channels.isEmpty else { return }
        
        // Upsert BundleEntry
        for channel in channels {
            let existingBundleEntry = bundleEntry(for: channel.id, channelBundleId: bundle.id)
            
            let bundleEntry = BundleEntry(channel: channel,
                                          channelBundle: bundle,
                                          sortHint: channel.sortHint,
                                          isFavorite: existingBundleEntry?.isFavorite ?? false)
            viewContext.insert(bundleEntry)
        }
    }
    
    private func removeBundleEntries(for channels: [Channel], from bundle: ChannelBundle) throws {
        guard !channels.isEmpty else { return }
        
        // Compute all IDs to remove from this bundle
        var expectedRemoveIds: [BundleEntryId] = []
        for channel in channels {
            expectedRemoveIds.append(BundleEntry.newBundleEntryId(channelBundleId: bundle.id, channelId: channel.id))
        }
        
        // Fetch existing entries to delete
        let removeEntryDescriptor = BundleEntryPredicate(bundleEntryIds: expectedRemoveIds).fetchDescriptor()
        let entriesToRemove = try viewContext.fetch(removeEntryDescriptor)
        
        // Delete them
        for bundleEntry in entriesToRemove {
            viewContext.delete(bundleEntry)
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
        
        let offlineDeviceIds = self.offlineDeviceIds()
        
        let channelsDescriptor = BundleEntryPredicate(channelBundleId: channelBundleId,
                                                      hasChannel: true,
                                                      showFavoritesOnly: showFavoritesOnly).fetchDescriptor()
        let bundleEntries: [BundleEntry] = (try context.fetch(channelsDescriptor))
        
        // BundleEntries that are not part of any offline device.
        let onlineBundleEntries: [BundleEntry] = bundleEntries.filter({ not(offlineDeviceIds.contains($0.channel!.deviceId)) })
        
        let channelIds = onlineBundleEntries.compactMap { $0.channel?.id }
        let map: ChannelMap =  onlineBundleEntries.reduce(into: [:]) { result, bundleEntry in
            // Create a mapping index mapping `Channel` identifier to the `BundleEntry` identifier.
            // Note: Can force unwrap channelId here because of the filtering above.
            result[bundleEntry.channel!.id] = bundleEntry.id
        }
        
        channelBundleMap.update(channelBundleId: channelBundleId,
                                map: map,
                                channelIds: channelIds)
        
        logDebug("Channel map built.  Total Channels: \(channelBundleMap.mapCount) 🏁")
    }
}
