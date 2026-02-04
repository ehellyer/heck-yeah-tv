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
final class MockSwiftDataController: SwiftDataProvider {
    
    //MARK: - SwiftDataController lifecycle
    
    deinit {
        rebuildTask?.cancel()
    }

    init(selectedCountry: CountryCodeId = "US",
         selectedCategory: CategoryId? = nil,
         searchTerm: String? = nil) {

        //Always use mock data stack for mock data so we don't accidentally persist the mock data to SQLite database.
        let stack = MockSwiftDataStack.shared
        self.viewContext = stack.viewContext
        self.container = stack.container 
        self.selectedCountry = selectedCountry
        self.selectedCategory = selectedCategory
        self.showFavoritesOnly = false
        self.searchTerm = searchTerm

        try? self.bootStrap()
    }
    
    //MARK: - Internal API - SwiftDataProvider implementation
    
    private(set) var channelBundleMap: ChannelBundleMap = ChannelBundleMap(channelBundleId: "", map: [:])
    
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
        let sort = [SortDescriptor<HomeRunDevice>(\.deviceId, order: .forward)]
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
        let fetchDescriptor = FetchDescriptor<ChannelBundle>()
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
//        logDebug("Deleting program data for programs that ended more than now.")
//        let now = Date()
//        let oldProgramsPredicate = #Predicate<ChannelProgram> { program in
//            program.endTime < now
//        }
//        try viewContext.delete(model: ChannelProgram.self, where: oldProgramsPredicate)
//        if viewContext.hasChanges {
//            try viewContext.save()
//        }
    }
    
    static func predicateBuilder(searchTerm: String?,
                                 countryCode: CountryCodeId,
                                 categoryId: CategoryId?) -> Predicate<Channel> {
        
        // Keeping the predicate builder code in the same spot for now.  (Less maintenance)  Change if needed.
        SwiftDataController.predicateBuilder(searchTerm: searchTerm,
                                             countryCode: countryCode,
                                             categoryId:  categoryId)
    }
    
    //MARK: - Internal API - ChannelFilterable implementation Properties (Observable)
    
    var showFavoritesOnly: Bool = false {
        didSet {
            guard showFavoritesOnly != oldValue else { return }
            Task { @MainActor in
                await scheduleChannelBundleMapRebuild()
            }
        }
    }
    
    var selectedCountry: CountryCodeId {
        didSet {
            guard selectedCountry != oldValue else { return }
            Task { @MainActor in
                await scheduleChannelBundleMapRebuild()
            }
        }
    }
    
    var selectedCategory: CategoryId? {
        didSet {
            guard selectedCategory != oldValue else { return }
            Task { @MainActor in
                await scheduleChannelBundleMapRebuild()
            }
        }
    }
    
    var searchTerm: String? {
        didSet {
            guard searchTerm != oldValue else { return }
            Task { @MainActor in
                await scheduleChannelBundleMapRebuild()
            }
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
    
    //MARK: - Private API - Functions
    
    private func bootStrap() throws {
        try rebuildChannelBundleMap()
    }

    /// Schedules a channel map rebuild with debouncing to prevent excessive rebuilds.
    ///
    /// This method cancels any pending rebuild and schedules a new one after a 300ms delay.
    private func scheduleChannelBundleMapRebuild() async {
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
        let channelBundleId = appState.selectedChannelBundle
        
        var conditions: [Predicate<BundleEntry>] = []
        conditions.append( #Predicate<BundleEntry> { bundleEntry in bundleEntry.channelBundle.id == channelBundleId } )
        if showFavoritesOnly {
            conditions.append(#Predicate<BundleEntry> { $0.isFavorite == true })
        }
        let compoundPredicate = conditions.reduce(#Predicate { _ in true }) { current, next in
            #Predicate { current.evaluate($0) && next.evaluate($0) }
        }
        let sortDescriptor: [SortDescriptor] = [SortDescriptor(\BundleEntry.sortHint, order: .forward)]
        let channelsDescriptor = FetchDescriptor<BundleEntry>(predicate: compoundPredicate, sortBy: sortDescriptor)
        let channels: [BundleEntry] = try context.fetch(channelsDescriptor)
        
        let map: ChannelMap =  channels.filter({ $0.channel != nil}).reduce(into: [:]) { result, item in
            // Note: Can force unwrap channelId here because of the filtering above.
            result[item.channel!.id] = item.id
        }
        
        channelBundleMap = ChannelBundleMap(channelBundleId: channelBundleId, map: map)
        
        logDebug("Channel map built.  Total Channels: \(channelBundleMap.mapCount) 🏁")
    }
}
