//
//  HDHomeRunImporter.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

actor HDHomeRunImporter {
    
    init(container: ModelContainer, scanForTuners: Bool) {
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
        self.scanForTuners = scanForTuners
    }
    
    private var batchCount: Int = 0
    private let batchSize: Int = 3000
    private let context: ModelContext
    private let scanForTuners: Bool
       
    private func importHDHRChannels(_ tunerChannels: [Channelable]) async throws {
        //Dev Note: Here `Channelable` is `HDHomeRunChannel`
        
        guard !tunerChannels.isEmpty else {
            logWarning("No HDHomeRun channels to import.")
            return
        }
        
        let existingFavorites: [ChannelId: IPTVFavorite] = {
            do {
                let channelSource: String = ChannelSourceType.homeRunTuner.rawValue
                let favs = try context.fetch(FetchDescriptor<IPTVFavorite>(predicate: #Predicate<IPTVFavorite> {
                    $0.channel?.source == channelSource
                    && $0.isFavorite == true
                }))
                let existingFavs = favs.reduce(into: [:]) { result, fav in
                    result[fav.id] = fav
                }
                return existingFavs
            } catch {
                logDebug("Unable to fetch existing favorites.")
                return [:]
            }
        }()
        
        logDebug("HDHomeRun channel import process Starting  (incoming: \(tunerChannels.count))... 🇺🇸")

        for src in tunerChannels {
            let newChannel = IPTVChannel(
                id: src.idHint,
                sortHint: src.sortHint,
                title: src.titleHint,
                number: src.numberHint,
                country: "ANY",
                categories: [],
                languages: [],
                url: src.urlHint,
                logoURL: nil,
                quality: src.qualityHint,
                hasDRM: src.hasDRMHint,
                source: src.sourceHint,
                deviceId: src.deviceIdHint,
                favorite: existingFavorites[src.idHint]
            )
            
            context.insert(newChannel)
            
            batchCount += 1
            
            if batchCount % batchSize == 0 {
                try context.save()
                await Task.yield()
            }
        }

        if context.hasChanges {
            try context.save()
        }
        
        logDebug("HDHomeRun channel import process completed  Total imported: \(tunerChannels.count)... 🏁")
    }
    
    func importTunerDevices(_ devices: [HDHomeRunDevice]) async throws {
        guard !devices.isEmpty else {
            logWarning("No devices to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Device import process starting... 🇺🇸")
        
        let existingHDHomeRunServers: [HDHomeRunServer] = {
            do {
                var descriptor = FetchDescriptor<HDHomeRunServer>()
                descriptor.propertiesToFetch = [\.deviceId]
                return try context.fetch(descriptor)
            } catch {
                logDebug("Unable to fetch existing `HDHomeRunServer`.")
                return []
            }
        }()
        
        let existingIDs = Set(existingHDHomeRunServers.map(\.deviceId))
        let incomingIDs = Set(devices.map(\.deviceId))
        
        // delete
        for model in existingHDHomeRunServers where !incomingIDs.contains(model.deviceId) {
            context.delete(model)
        }
        
        // insert
        for src in devices where !existingIDs.contains(src.deviceId) {
            context.insert(
                HDHomeRunServer(deviceId: src.deviceId,
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
        
        logDebug("Device import process completed. Total imported: \(devices.count) 🏁")
    }
    
    //MARK: - Public API
    
    func load() async throws -> FetchSummary {
        var summary = FetchSummary()
        
        let hdHomeRunController = HDHomeRunDiscoveryController()
        
        let hdHomeRunSummary = await hdHomeRunController.bootStrapTunerChannelDiscovery()
        summary.mergeSummary(hdHomeRunSummary)
        
        if summary.failures.count > 0 {
            logError("\(summary.failures.count) failure(s) in HDHomeRun tuner fetch: \(summary.failures)")
        }
        
        try await self.importTunerDevices(hdHomeRunController.devices)
        try await self.importHDHRChannels(hdHomeRunController.channels)
        
        return summary
    }
}
