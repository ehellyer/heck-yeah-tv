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
    
    init(container: ModelContainer) {
        self.context = ModelContext(container)
        self.context.autosaveEnabled = false
    }

    private var batchCount: Int = 0
    private let batchSize: Int = 3000
    private let context: ModelContext
    
    private lazy var existingFavorites: [ChannelId: IPTVFavorite] = {
        do {
            let favs = try context.fetch(FetchDescriptor<IPTVFavorite>(predicate: #Predicate<IPTVFavorite> { $0.isFavorite == true }))
            let existingFavs = favs.reduce(into: [:]) { result, fav in
                result[fav.id] = fav
            }
            return existingFavs
        } catch {
            logDebug("Unable to fetch existing favorites.")
            return [:]
        }
    }()
    
    private lazy var existingCategories: [IPTVCategory] = {
        do {
            return try context.fetch(FetchDescriptor<IPTVCategory>())
        } catch {
            logDebug("Unable to fetch categories.")
            return []
        }
    }()

    private func iptvChannel(for channelId: ChannelId) -> IPTVChannel? {
        do {
            let predicate: Predicate<IPTVChannel> = #Predicate { $0.id == channelId }
            var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
            descriptor.fetchLimit = 1
            return try context.fetch(descriptor).first
        } catch {
            logDebug("Unable to fetch existing `IPTVChannel` .")
            return nil
        }
    }
    
    func importChannels(feeds: [IPFeed],
                        logos: [IPLogo],
                        channels: [IPChannel],
                        streams: [IPStream],
                        tunerChannels: [HDHomeRunChannel]) async throws {
        
        //Clean up the streams, remove duplicates
        var streams = streams
        let remove = Array(Dictionary(grouping: streams, by: \.id).filter({ $1.count > 1 }).keys)
        streams.removeAll(where: { remove.contains($0.id) })
        
        //Clean up the streams, remove streams without channel and feed identifiers.
        streams = streams.filter( { $0.channelId != nil && $0.feedId != nil })
        
        //Delete all existing channels, faster than upsert.  (We preserve favorites).
        try context.delete(model: IPTVChannel.self, where: #Predicate { _ in true })
        if context.hasChanges {
            try context.save()
        }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.importHDHRChannels(tunerChannels: tunerChannels)
            }
            group.addTask {
                try await self.importIPChannels(ipFeeds: feeds,
                                                ipLogos: logos,
                                                ipChannels: channels,
                                                ipStreams: streams)
            }
            try await group.waitForAll()
        }
    }

    private func importHDHRChannels(tunerChannels: [Channelable]) async throws {
        //Dev Note: Here `Channelable` is `HDHomeRunChannel`
        
        guard !tunerChannels.isEmpty else {
            logWarning("No HDHomeRun channels to import.")
            return
        }
        
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
                favorite: self.existingFavorites[src.idHint]
            )
            
            context.insert(newChannel)
        }

        if context.hasChanges {
            try context.save()
        }
        
        logDebug("HDHomeRun channel import process completed  Total imported: \(tunerChannels.count)... 🏁")
    }
    
    private func importIPChannels(ipFeeds: [IPFeed],
                                  ipLogos: [IPLogo],
                                  ipChannels: [IPChannel],
                                  ipStreams: [Channelable]) async throws {
        //Dev Note: Here `Channelable` is `IPStream`
        
        guard !ipStreams.isEmpty else {
            logWarning("No IP channels to import.")
            return
        }
        
        logDebug("IP channel import process Starting  (incoming: \(ipStreams.count))... 🇺🇸")

        //Build import indexes
        let feeds: [ChannelId: (StreamQuality, [LanguageCode])] = ipFeeds.reduce(into: [:]) { result, feed in
            result[feed.channelId] = (StreamQuality.convertToStreamQuality(feed.format), feed.languages)
        }
        let logos: [ChannelId: String?] = ipLogos.reduce(into: [:]) { result, iplogo in
            result[iplogo.channelId] = iplogo.url
        }
        let ipChannels: [ChannelId: (CountryCode, [IPTVCategory]?)] = ipChannels.reduce(into: [:]) { result, channel in
            result[channel.channelId] = (channel.country, self.existingCategories.filter( { channel.categories?.contains($0.categoryId) == true }))
        }

//        var descriptor = FetchDescriptor<IPTVChannel>()
//        descriptor.propertiesToFetch = [\.id]
//        let models = try context.fetch(descriptor)
//        let existingIds: Set<ChannelId> = Set(models.map(\.id))
        
        // insert
        for src in ipStreams { //where !existingIds.contains(src.idHint) {
                        
            let iptvChannelId: String? = (src as! IPStream).channelId
            
            let feed = (iptvChannelId == nil) ? nil : feeds[iptvChannelId!]
            let format = feed?.0 ?? .unknown
            let languages = feed?.1 ?? []
            var logoURL: URL? = nil
            if let iptvChannelId, let strURL = (logos[iptvChannelId] ?? nil), let url = URL(string: strURL) {
                logoURL = url
            }
            let country = (iptvChannelId == nil) ? "US" : ipChannels[iptvChannelId!]?.0 ?? "US"
            let categories = (iptvChannelId == nil) ? [] : ipChannels[iptvChannelId!]?.1 ?? []
            
            let newChannel = IPTVChannel(
                id: src.idHint,
                sortHint: src.sortHint,
                title: src.titleHint,
                number: src.numberHint,
                country: country,
                categories: categories,
                languages: languages,
                url: src.urlHint,
                logoURL: logoURL,
                quality: format,
                hasDRM: src.hasDRMHint,
                source: src.sourceHint,
                deviceId: src.deviceIdHint,
                favorite: self.existingFavorites[src.idHint]
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
        
        logDebug("Channel import process completed. Total imported: \(ipStreams.count) 🏁")
    }
    
    func importCountries(_ countries: [Country]) async throws {
        guard !countries.isEmpty else {
            logWarning("No countries to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Country import process starting... 🇺🇸")
        
        // insert or update
        for src in countries {
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
    
    func importCategories(_ categories: [IPCategory]) async throws {
        guard !categories.isEmpty else {
            logWarning("No categories to import, exiting process without changes to local store.")
            return
        }

        // No smut category.
        let categories = categories.filter({ $0.categoryId != "xxx" })
        
        logDebug("Category import process starting... 🇺🇸")

        // insert or update
        for src in categories {
            context.insert(
                IPTVCategory(categoryId: src.categoryId,
                             name: src.name,
                             categoryDescription: src.description)
            )
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        logDebug("Categories import process completed. Total imported: \(categories.count) 🏁")
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
}
