//
//  ChannelImporter.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

actor ChannelImporter {
    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
    }

    func importChannels(streams: [IPStream], tunerChannels: [HDHomeRunChannel]) async throws {
        guard !streams.isEmpty || !tunerChannels.isEmpty else { return }
       
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

        // update
//        for model in existing where incomingIDs.contains(model.id) {
//            if let src = incoming.first(where: { $0.idHint == model.id }) {
//                model.title    = src.titleHint
//                model.number   = src.numberHint
//                model.url      = src.urlHint
//                model.sortHint = src.sortHint
//                model.quality  = src.qualityHint
//                model.hasDRM   = src.hasDRMHint
//                model.source   = src.sourceHint
//            }
//        }
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    func buildChannelMap(showFavoritesOnly: Bool) async throws {
        
        logConsole("Channel map building...")
        
        var channelsDescriptor: FetchDescriptor<IPTVChannel> = FetchDescriptor<IPTVChannel>(
            sortBy: [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
        )
        
        channelsDescriptor.predicate = (showFavoritesOnly ? (#Predicate<IPTVChannel> { $0.isFavorite == true }) : nil)
        let channels: [IPTVChannel] = try context.fetch(channelsDescriptor)
        let map: [ChannelId] = channels.map { $0.id }
        
        // Replace existing singleton map (if any), then insert the new one
        let channelMapPredicate = #Predicate<IPTVChannelMap> { $0.id == channelMapKey }
        let existingMaps = try context.fetch(FetchDescriptor<IPTVChannelMap>(predicate: channelMapPredicate))
        for m in existingMaps {
            context.delete(m)
        }
        
        context.insert(
            IPTVChannelMap(map: map)
        )
        
        if context.hasChanges {
            try context.save()
        }
        
        logConsole("Channel map built")
    }
}
