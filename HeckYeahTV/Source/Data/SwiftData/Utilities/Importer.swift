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
        let existing = try context.fetch(FetchDescriptor<IPTVChannel>())

        let incoming: [Channelable] = streams + tunerChannels
        let existingIDs = Set(existing.map(\.id))
        let incomingIDs = Set(incoming.map(\.idHint))

        // delete
        for model in existing where !incomingIDs.contains(model.id) {
            context.delete(model)
        }

        // insert
        for src in incoming where !existingIDs.contains(src.idHint) {
            context.insert(
                IPTVChannel(id: src.idHint,
                            sortHint: src.sortHint,
                            title: src.titleHint,
                            number: src.numberHint,
                            url: src.urlHint,
                            logoURL: nil,
                            quality: src.qualityHint,
                            hasDRM: src.hasDRMHint,
                            source: src.sourceHint)
            )
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
}
