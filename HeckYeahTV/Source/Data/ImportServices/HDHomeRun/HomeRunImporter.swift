//
//  HomeRunImporter.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

@ModelActor
actor HomeRunImporter {
    
    deinit {
        logDebug("Deallocated")
    }
    
    @Injected(\.sharedAppState) private var appState: AppStateProvider
    
    private var batchCount: Int = 0
    private let batchSize: Int = 500

    private func fetchChannel(id: ChannelId) async throws -> Channel? {
        var chDescriptor = ChannelPredicate(channelId: id).fetchDescriptor()
        chDescriptor.fetchLimit = 1
        let model = try modelContext.fetch(chDescriptor).first
        return model
    }
    
    private func importHDHRChannels(_ tunerChannels: [Channelable]) async throws {
                      
        guard !tunerChannels.isEmpty else {
            logWarning("No HDHomeRun channels to import.")
            return
        }
        
        let deviceIds = Array(Set(tunerChannels.map { $0.deviceIdHint }))
        
        let existingChannels: [Channel] = {
            do {
                var descriptor = ChannelPredicate(deviceIds: deviceIds).fetchDescriptor()
                descriptor.propertiesToFetch = [\.id, \.logoURL]
                return try modelContext.fetch(descriptor)
            } catch {
                logError("Unable to fetch existing `HDHomeRun Channels` from SwiftData.")
                return []
            }
        }()
        
        // Create a map of existing channel IDs to their logo URLs for preservation
        let existingLogoURLs: [ChannelId: URL?] = existingChannels.reduce(into: [:]) { result, channel in
            result[channel.id] = channel.logoURL
        }
        
        let incomingIDs = Set(tunerChannels.map(\.idHint))
        
        // delete
        logDebug("Existing HomeRun channels to delete: \(existingChannels.count)")
        for channel in existingChannels where !incomingIDs.contains(channel.id) {
            modelContext.delete(channel)
        }
        
        // insert
        logDebug("HomeRun channel import process Starting  (incoming: \(tunerChannels.count))... 🇺🇸")
        for src in tunerChannels {
            
            // Preserve existing logoURL if the new one is nil
            let logoURL: URL? = src.logoURLHint ?? existingLogoURLs[src.idHint] ?? nil
            
            let newChannel = Channel(
                id: src.idHint,
                guideId: src.guideIdHint,
                sortHint: src.sortHint,
                title: src.titleHint,
                number: src.numberHint,
                country: "ANY",
                categories: [],
                languages: [],
                url: src.urlHint,
                logoURL: logoURL,
                quality: src.qualityHint,
                hasDRM: src.hasDRMHint,
                deviceId: src.deviceIdHint
            )
            modelContext.insert(newChannel)
            
            batchCount += 1
            
            if batchCount % batchSize == 0 {
                try modelContext.save()
                await Task.yield()
            }
        }

        if modelContext.hasChanges {
            try modelContext.save()
            await Task.yield()
        }
        
        logDebug("HomeRun channel import process completed  Total imported: \(tunerChannels.count)... 🏁")
    }
    
    private func importTunerDevices(_ discoveredDevices: [HDHomeRunDevice]) async throws {
        if discoveredDevices.isEmpty {
            logWarning("No devices to import. Updating local store to remove any devices.  Channels associated with removed devices will also be removed.")
        }
        
        logDebug("HomeRun Device import process starting... 🇺🇸")
        
        let existingDevices: [HomeRunDevice] = {
            do {
                return try modelContext.fetch(HomeRunDevicePredicate().fetchDescriptor())
            } catch {
                logError("Unable to fetch existing `HomeRunDevice`. \(error)")
                return []
            }
        }()
        
        let discoveredDeviceIds = Set(discoveredDevices.map(\.deviceId))
        let offlineDevices = existingDevices.filter({ not(discoveredDeviceIds.contains($0.deviceId)) })

        // Mark devices as offline if they exist in the database but were not discovered on the network.
        for device in offlineDevices {
            device.isOffline = true
        }
        
        // DiscoveredDevices collection insert/update. (aka Upsert done by SwiftData on DeviceId)
        for src in discoveredDevices {
            modelContext.insert(
                HomeRunDevice(deviceId: src.deviceId,
                              friendlyName: src.friendlyName,
                              modelNumber: src.modelNumber,
                              firmwareName: src.firmwareName,
                              firmwareVersion: src.firmwareVersion,
                              deviceAuth: src.deviceAuth,
                              baseURL: src.baseURL,
                              lineupURL: src.lineupURL,
                              tunerCount: src.tunerCount,
                              isEnabled: true,
                              isOffline: false)  // <-- An upsert will flip an isOffline == true to isOffline == false.
            )
        }
        
        if modelContext.hasChanges {
            try modelContext.save()
            await Task.yield()
        }
        
        logDebug("HomeRun Device import process completed. Total imported: \(discoveredDevices.count) 🏁")
    }
    
    
    private func updateChannelBundleDevice() async {
        do {
            let devices: [HomeRunDevice] = try modelContext.fetch(HomeRunDevicePredicate().fetchDescriptor())
            
            guard devices.count == 1, let device = devices.first, device.isEnabled == true else { return }
                
            let channelBundles = try modelContext.fetch(ChannelBundlePredicate().fetchDescriptor())
            for bundle in channelBundles {
                bundle.deviceAssociations.append(ChannelBundleDevice(bundle: bundle, device: device))
            }
            
            if modelContext.hasChanges {
                try modelContext.save()
                await Task.yield()
            }
        } catch {
            logError("Unable to update ChannelBundles with discovered `HomeRunDevice`. \(error)")
        }
    }
    
    /// Dev note: Cleanup of the channel guides is done by time only.  A separate function will clean up any channel programs with an EndTime older than now.
    /// The cleanup function is called once on cold app launch and once every time the guide is launched.
    private func importChannelGuides( _ channelGuides: [HDHomeRunChannelGuide], guideToChannelMap: [GuideNumber: ChannelId]) async throws {
        guard not(channelGuides.isEmpty) else {
            logWarning("No channel guides to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("HomeRun Channel guide import process starting... 🇺🇸")
        
        // insert
        for guide in channelGuides {
            if let channelId = guideToChannelMap[guide.guideNumber] {
                for program in guide.programs {
                    let id: ChannelProgramId = String.stableHashHex(channelId, program.startTime.ISO8601Format())
                    modelContext.insert(
                        ChannelProgram(id: id,
                                       channelId: channelId,
                                       startTime: program.startTime,
                                       endTime: program.endTime,
                                       first: program.first,
                                       title: program.title,
                                       episodeNumber: program.episodeNumber,
                                       episodeTitle: program.episodeTitle,
                                       synopsis: program.synopsis,
                                       originalAirDate: program.originalAirdate,
                                       programImageURL: program.imageURL,
                                       recordingRule: program.recordingRule,
                                       filter: program.filter ?? [])
                    )
                    
                    batchCount += 1
                    
                    if batchCount % batchSize == 0 {
                        try modelContext.save()
                        await Task.yield()
                    }
                }
            }
        }
        
        if modelContext.hasChanges {
            try modelContext.save()
            await Task.yield()
        }
        
        logDebug("HomeRun Channel guide import process completed. Total guides imported for \(channelGuides.count) channels. 🏁")
    }
    
    /// Updates the last guide fetch timestamp to the current date/time.
    /// Call this after successfully fetching and importing guide data.
    private func updateHomeRunChannelProgramFetchDate() async {
        await MainActor.run {
            let updatedDate = Date()
            var actorAppState: AppStateProvider = InjectedValues[\.sharedAppState]
            actorAppState.dateLastHomeRunChannelProgramFetch = updatedDate
            logDebug("Updated appState.dateLastHomeRunChannelProgramFetch to: \(updatedDate)")
        }
    }
    
    //MARK: - Internal API
    
    // A tuner device might go offline, be removed, or the application host device itself might be on a network that can no longer reach the tuner device.
    // This function identifies channels not from IPTV source that have no associated HomeRunDevice.  They are orphaned.
    // Returns the count of orphaned tuner channels got removed.
    func deleteOrphanedTunerChannels() async {
        do {
            logDebug("Starting cleanup of orphaned tuner channels...")
            
            // Step 1: Get unique list of deviceIds from Channels (excluding IPTV channels)
            var channelDescriptor = ChannelPredicate(deviceChannelsOnly: true).fetchDescriptor()
            channelDescriptor.propertiesToFetch = [\.deviceId]
            
            let homeRunChannels = try modelContext.fetch(channelDescriptor)
            let uniqueDeviceIds = Set(homeRunChannels.map { $0.deviceId })
            
            logDebug("Found \(uniqueDeviceIds.count) unique device IDs in channels (excluding IPTV channels).")
            
            // Step 2: For each deviceId, check if it exists in HomeRunDevices
            var orphanedDeviceIds: [HDHomeRunDeviceId] = []
            
            for deviceId in uniqueDeviceIds {
                let deviceDescriptor = HomeRunDevicePredicate(deviceIds: [deviceId]).fetchDescriptor()
                let device = try modelContext.fetch(deviceDescriptor).first
                
                // If the device has been removed or is currently offline, remove its channels from the channel catalog.  (Leave the bundle entries)
                if device == nil || device?.isOffline == true {
                    orphanedDeviceIds.append(deviceId)
                }
            }
            
            // Step 3: Delete channels with orphaned deviceIds
            guard !orphanedDeviceIds.isEmpty else {
                logDebug("No orphaned channels found. ✅")
                return
            }
            
            logDebug("Found \(orphanedDeviceIds.count) orphaned device IDs: \(orphanedDeviceIds)")
            
            let deleteChannelPredicate = #Predicate<Channel> { channel in
                orphanedDeviceIds.contains(channel.deviceId)
            }
            
            try modelContext.delete(model: Channel.self, where: deleteChannelPredicate)
            
            if modelContext.hasChanges {
                try modelContext.save()
            }
            
            logDebug("Successfully deleted orphaned channels. 🤘🏻 🏁")
        } catch {
            logError("Failed to delete orphaned tuner channels. Error: \(error)")
        }
    }
    
    func load(shouldFetchGuideData: Bool) async throws -> FetchSummary {
        
        // Guard against concurrent execution
        let isAlreadyLoading = await MainActor.run {
            let appState: AppStateProvider = InjectedValues[\.sharedAppState]
            return appState.isReloadingHomeRun
        }
        
        guard !isAlreadyLoading else {
            logWarning("HomeRun import already in progress, skipping concurrent execution")
            return FetchSummary()
        }
        
        // Set loading state
        await MainActor.run {
            var appState: AppStateProvider = InjectedValues[\.sharedAppState]
            appState.isReloadingHomeRun = true
        }
        
        defer {
            Task { @MainActor in
                var appState: AppStateProvider = InjectedValues[\.sharedAppState]
                appState.isReloadingHomeRun = false
            }
        }

        var summary = FetchSummary()
        
        let homeRunController: HomeRunController = HomeRunController()

        let homeRunSummary = await homeRunController.fetchAll(includeGuideData: shouldFetchGuideData)
        
        summary.mergeSummary(homeRunSummary)
        
        if not(summary.failures.isEmpty) {
            logError("\(summary.failures.count) failure(s) in HDHomeRun tuner fetch: \(summary.failures)")
        }
        
        try await self.importTunerDevices(homeRunController.devices)
        try await self.importHDHRChannels(homeRunController.channels)
        
        /// If after the imports there is only one device in the database and it is enabled for use in the app, it is automatically added to all ChannelBundles.
        await self.updateChannelBundleDevice()

        if shouldFetchGuideData {
            let guideToChannelMap: [GuideNumber : ChannelId] = await homeRunController.channels.reduce(into: [:]) { accumulator, channel in
                accumulator[channel.guideNumber] = channel.id
            }
            
            do {
                try await self.importChannelGuides(homeRunController.channelGuides,
                                                   guideToChannelMap: guideToChannelMap)
                
                // Only update the timestamp if guide import was successful
                if guideToChannelMap.count > 0 {
                    await self.updateHomeRunChannelProgramFetchDate()
                }                
            } catch {
                logError("Failed to import channel guides: \(error)")
                throw error
            }
        } else {
            logDebug("Skipping guide data fetch. Last fetch was recent enough.")
        }

        return summary
    }
}
