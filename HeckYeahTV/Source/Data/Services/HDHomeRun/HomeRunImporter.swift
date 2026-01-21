//
//  HomeRunImporter.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

actor HomeRunImporter {
    
    init(container: ModelContainer, scanForTuners: Bool) {
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
        self.scanForTuners = scanForTuners
    }
    
    private var batchCount: Int = 0
    private let batchSize: Int = 3000
    private let context: ModelContext
    private let scanForTuners: Bool

    private func fetchChannel(id: ChannelId) async throws -> Channel? {
        let chPredicate = #Predicate<Channel> { $0.id == id }
        var chDescriptor = FetchDescriptor<Channel>(predicate: chPredicate)
        chDescriptor.fetchLimit = 1
        let model = try context.fetch(chDescriptor).first
        return model
    }
    
    private func importHDHRChannels(_ tunerChannels: [Channelable]) async throws {
        //Dev Note: Here `Channelable` is `HDHomeRunChannel`
        
        guard !tunerChannels.isEmpty else {
            logWarning("No HDHomeRun channels to import.")
            return
        }
        
        let existingFavorites: [ChannelId: Favorite] = {
            do {
                let favs = try context.fetch(FetchDescriptor<Favorite>(predicate: #Predicate<Favorite> { $0.isFavorite == true }))
                let existingFavs = favs.reduce(into: [:]) { result, fav in
                    result[fav.id] = fav
                }
                return existingFavs
            } catch {
                logDebug("Unable to fetch existing favorites.")
                return [:]
            }
        }()
        
        logDebug("HomeRun channel import process Starting  (incoming: \(tunerChannels.count))... 🇺🇸")

        for src in tunerChannels {
            
            if let channel = try await fetchChannel(id: src.idHint) {
                channel.favorite = existingFavorites[src.idHint]
                channel.logoURL = src.logoURLHint
            } else {
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
                    source: src.sourceHint,
                    deviceId: src.deviceIdHint,
                    favorite: existingFavorites[src.idHint]
                )
                context.insert(newChannel)
            }
            
            batchCount += 1
            
            if batchCount % batchSize == 0 {
                try context.save()
//                await Task.yield()
            }
        }

        if context.hasChanges {
            try context.save()
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
                return try context.fetch(descriptor)
            } catch {
                logDebug("Unable to fetch existing `HomeRunDevice`.")
                return []
            }
        }()
        
        let existingIDs = Set(existingHomeRunDevices.map(\.deviceId))
        let incomingIDs = Set(devices.map(\.deviceId))
        
        // delete
        for model in existingHomeRunDevices where !incomingIDs.contains(model.deviceId) {
            context.delete(model)
        }
        
        // insert
        for src in devices where !existingIDs.contains(src.deviceId) {
            context.insert(
                HomeRunDevice(deviceId: src.deviceId,
                                friendlyName: src.friendlyName,
                                modelNumber: src.modelNumber,
                                firmwareName: src.firmwareName,
                                firmwareVersion: src.firmwareVersion,
                                deviceAuth: src.deviceAuth,
                                baseURL: src.baseURL,
                                lineupURL: src.lineupURL,
                                tunerCount: src.tunerCount,
                                includeChannelLineUp: true)
            )
        }
        
//        // For runtime debug only.  Simulates no tuners in the DB.
//        for model in existing {
//            context.delete(model)
//        }
        
        if context.hasChanges {
            try context.save()
        }
        
        logDebug("HomeRun Device import process completed. Total imported: \(devices.count) 🏁")
    }
    
    private func importChannelGuides( _ channelGuides: [HDHomeRunChannelGuide], channelGuideMap: [GuideNumber: ChannelId]) async throws {
        guard !channelGuides.isEmpty else {
            logWarning("No channel guides to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("HomeRun Channel guide import process starting... 🇺🇸")
        
        // delete - programs that ended more than 16 hours
        logDebug("Deleting program data for programs that ended more than 16 hours ago.")
        let sixteenHoursAgo = Date().addingTimeInterval(-16 * 60 * 60)
        let oldProgramsPredicate = #Predicate<ChannelProgram> { program in
            program.endTime < sixteenHoursAgo
        }
        try context.delete(model: ChannelProgram.self, where: oldProgramsPredicate)
        if context.hasChanges {
            try context.save()
        }
        
        // insert
        for guide in channelGuides {
            if let channelId = channelGuideMap[guide.guideNumber] {
                for program in guide.programs {
                    let id: ChannelProgramId = String.stableHashHex(channelId, program.startTime.ISO8601Format())
                    context.insert(
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
                }
            }
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        logDebug("HomeRun Channel guide import process completed. Total guides imported for \(channelGuides.count) channels. 🏁")
    }
    
    /// Updates the last guide fetch timestamp to the current date/time.
    /// Call this after successfully fetching and importing guide data.
    private func updateLastGuideFetchDate() async {
        await MainActor.run {
            let updatedDate = Date()
            SharedAppState.shared.dateLastGuideFetch = updatedDate
            logDebug("Updated dateLastGuideFetch to: \(updatedDate)")
        }
    }
    
    //MARK: - Public API
    
    func load() async throws -> FetchSummary {
        var summary = FetchSummary()
        
        let homeRunController: HomeRunDiscoveryController = HomeRunDiscoveryController()

        let lastGuideFetchDate: Date? = await SharedAppState.shared.dateLastGuideFetch

        let shouldFetchGuideData: Bool = {
            guard let lastFetchDate = lastGuideFetchDate else {
                // Never fetched before, should fetch now
                return true
            }
            
            // Random interval between 5 and 10 hours
            let randomHours = Double.random(in: 5...10)
            let intervalSinceLastFetch = Date().timeIntervalSince(lastFetchDate)
            let hoursElapsed = intervalSinceLastFetch / 3600 // Convert seconds to hours
            
            return hoursElapsed >= randomHours
        }()
        
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
                await self.updateLastGuideFetchDate()
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
