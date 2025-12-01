//
//  Importer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

actor Importer {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
    }

    func importChannels(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) async throws {
        guard !streams.isEmpty || !tunerChannels.isEmpty else {
            logWarning("No channels to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Channel Import Process Starting... 🏳️")
        
        let incoming: [Channelable] = streams + tunerChannels
        let incomingIDs = Set(incoming.map(\.idHint))
        
        let existing = try context.fetch(FetchDescriptor<IPTVChannel>())
        let existingIDs = Set(existing.map(\.id))
        
        // delete
        for model in existing where !incomingIDs.contains(model.id) {
            context.delete(model)
        }
        
        // insert
        for src in incoming where !existingIDs.contains(src.idHint) {
            context.insert(
                IPTVChannel(
                    id: src.idHint,
                    sortHint: src.sortHint,
                    title: src.titleHint,
                    number: src.numberHint,
                    url: src.urlHint,
                    logoURL: nil,
                    quality: src.qualityHint,
                    hasDRM: src.hasDRMHint,
                    source: src.sourceHint
                )
            )
        }
        
        // update (Only for HDHomeRun channels missing associated deviceId data for source enum).
        let exitingHomeRunChannels = existing.filter({ $0.source == SchemaV2.ChannelSource.homeRunTuner(deviceId: "") })
        for channel in exitingHomeRunChannels {
            // Update the source if it was a placeholder
            if case .homeRunTuner(let deviceId) = incoming.first(where: { $0.idHint == channel.id })?.sourceHint {
                channel.source = .homeRunTuner(deviceId: deviceId)
            }
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        logDebug("Channel import process completed. Total imported: \(incoming.count) 🏁")
    }
    
    func buildChannelMap(showFavoritesOnly: Bool) async throws -> ChannelMap {

        if context.hasChanges {
            logWarning("Unsaved changes prior to building channel map, saving...")
            try context.save()
        }
        
        logDebug("Building Channel Map... 🏳️")
        
        var channelsDescriptor: FetchDescriptor<IPTVChannel> = FetchDescriptor<IPTVChannel>(
            sortBy: [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
        )
        
        channelsDescriptor.predicate = (showFavoritesOnly ? (#Predicate<IPTVChannel> { $0.isFavorite == true }) : nil)
        let channels: [IPTVChannel] = try context.fetch(channelsDescriptor)
        let map: [ChannelId] = channels.map { $0.id }
        let cm = ChannelMap(map: map)

        logDebug("Channel map built.  Total Channels: \(cm.totalCount) 🏁")
        return cm
    }
    
    func importCountries(_ countries : [Country]) async throws {
        guard !countries.isEmpty else {
            logWarning("No countries to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Country import process starting... 🏳️")

        let existing = try context.fetch(FetchDescriptor<IPTVCountry>())
        let existingIDs = Set(existing.map(\.code))
        let incomingIDs = Set(countries.map(\.code))
        
        // delete
        for model in existing where !incomingIDs.contains(model.code) {
            context.delete(model)
        }
        
        // insert
        for src in countries where !existingIDs.contains(src.code) {
            context.insert(
                IPTVCountry(name: src.name,
                            code: src.code,
                            languages: src.languages,
                            flag: src.flag)
            )
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        logDebug("Country import process completed. Total imported: \(countries.count) 🏁")
    }
    
    func importTunerDevices(_ devices : [HDHomeRunDevice]) async throws {
        guard !devices.isEmpty else {
            logWarning("No devices to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Device import process starting... 🏳️")
        
        let existing = try context.fetch(FetchDescriptor<HDHomeRunServer>())
        let existingIDs = Set(existing.map(\.deviceId))
        let incomingIDs = Set(devices.map(\.deviceId))
        
        // delete
        for model in existing where !incomingIDs.contains(model.deviceId) {
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
}
