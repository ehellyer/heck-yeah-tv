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
        let chPredicate = #Predicate<Channel> { $0.id == id }
        var chDescriptor = FetchDescriptor<Channel>(predicate: chPredicate)
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
                let predicate = #Predicate<Channel> { deviceIds.contains($0.deviceId) }
                var descriptor = FetchDescriptor<Channel>(predicate: predicate)
                descriptor.propertiesToFetch = [\.id]
                return try modelContext.fetch(descriptor)
            } catch {
                logError("Unable to fetch existing `HDHomeRun Channels` from SwiftData.")
                return []
            }
        }()
        
//        let existingIDs = Set(existingChannels.map(\.id))
        let incomingIDs = Set(tunerChannels.map(\.idHint))
        
        // delete
        logDebug("Existing HomeRun channels to delete: \(existingChannels.count)")
        for model in existingChannels where !incomingIDs.contains(model.id) {
            modelContext.delete(model)
        }
        
        // insert
        logDebug("HomeRun channel import process Starting  (incoming: \(tunerChannels.count))... 🇺🇸")
        for src in tunerChannels {
            
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
                logoURL: src.logoURLHint,
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
    
    private func importTunerDevices(_ devices: [HDHomeRunDevice]) async throws {
        guard !devices.isEmpty else {
            logWarning("No devices to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("HomeRun Device import process starting... 🇺🇸")
        
        let existingHomeRunDevices: [HomeRunDevice] = {
            do {
                var descriptor = FetchDescriptor<HomeRunDevice>()
                descriptor.propertiesToFetch = [\.deviceId]
                return try modelContext.fetch(descriptor)
            } catch {
                logError("Unable to fetch existing `HomeRunDevice`. \(error)")
                return []
            }
        }()
        
        let existingIDs = Set(existingHomeRunDevices.map(\.deviceId))
        let incomingIDs = Set(devices.map(\.deviceId))
        
        // delete
        for model in existingHomeRunDevices where !incomingIDs.contains(model.deviceId) {
            modelContext.delete(model)
        }
        
        // insert
        for src in devices where !existingIDs.contains(src.deviceId) {
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
                                isEnabled: true)
            )
        }
        
//        // For runtime debug only.  Simulates no tuners in the DB.
//        for model in existing {
//            context.delete(model)
//        }
        
        if modelContext.hasChanges {
            try modelContext.save()
            await Task.yield()
        }
        
        logDebug("HomeRun Device import process completed. Total imported: \(devices.count) 🏁")
    }
    
    private func importChannelGuides( _ channelGuides: [HDHomeRunChannelGuide], channelGuideMap: [GuideNumber: ChannelId]) async throws {
        guard !channelGuides.isEmpty else {
            logWarning("No channel guides to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("HomeRun Channel guide import process starting... 🇺🇸")
        
        // insert
        for guide in channelGuides {
            if let channelId = channelGuideMap[guide.guideNumber] {
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
    
    func load(shouldFetchGuideData: Bool) async throws -> FetchSummary {

        var summary = FetchSummary()
        
        let homeRunController: HomeRunController = HomeRunController()

        let homeRunSummary = await homeRunController.fetchAll(includeGuideData: shouldFetchGuideData)
        
        summary.mergeSummary(homeRunSummary)
        
        if summary.failures.isEmpty == false {
            logError("\(summary.failures.count) failure(s) in HDHomeRun tuner fetch: \(summary.failures)")
        }
        
        try await self.importTunerDevices(homeRunController.devices)
        try await self.importHDHRChannels(homeRunController.channels)
        
        if shouldFetchGuideData {
            let channelGuideMap: [GuideNumber : ChannelId] = await homeRunController.channels.reduce(into: [:]) { accumulator, channel in
                accumulator[channel.guideNumber] = channel.id
            }
            
            do {
                try await self.importChannelGuides(homeRunController.channelGuides, channelGuideMap: channelGuideMap)
                
                // Only update the timestamp if guide import was successful
                if channelGuideMap.count > 0 {
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
