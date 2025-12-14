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

    struct ImportStruct {
        var format: StreamQuality
        var languages: [String]
        var logoURL: URL?
        var country: CountryCode
        var categories: [IPTVCategory]
        var favorite: IPTVFavorite?
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
    
    private lazy var existingCountries: [IPTVCountry] = {
        do {
            return try context.fetch(FetchDescriptor<IPTVCountry>())
        } catch {
            logDebug("Unable to fetch countries.")
            return []
        }
    }()
    
    private lazy var existingHDHomeRunServers: [HDHomeRunServer] = {
        do {
            return try context.fetch(FetchDescriptor<HDHomeRunServer>())
        } catch {
            logDebug("Unable to fetch existing `HDHomeRunServer`.")
            return []
        }
    }()
    
    private lazy var existingHDHomeRunChannels: [IPTVChannel] = {
        do {
            let source = ChannelSourceType.homeRunTuner.rawValue
            let predicate: Predicate<IPTVChannel> = #Predicate { $0.source == source }
            return try context.fetch(FetchDescriptor<IPTVChannel>(predicate: predicate))
        } catch {
            logDebug("Unable to fetch existing `IPTVChannel` that are source of `HDHomeRunChannel`.")
            return []
        }
    }()

    private lazy var existingIPStreamChannels: [IPTVChannel] = {
        do {
            let source = ChannelSourceType.ipStream.rawValue
            let predicate: Predicate<IPTVChannel> = #Predicate { $0.source == source }
            return try context.fetch(FetchDescriptor<IPTVChannel>(predicate: predicate))
        } catch {
            logDebug("Unable to fetch existing `IPTVChannel` that are source of `IPStream`.")
            return []
        }
    }()
    
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
        
        //Delete all existing channels.  (We keep favorites).  Faster than upsert.
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
        
        logDebug("HDHomeRun channel Import Process Starting  (incoming: \(tunerChannels.count))... 🇺🇸")

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
            batchCount += 1
            
            if batchCount % batchSize == 0 {
                try context.save()
            }
        }
        
        logDebug("End Loop")
        
        if context.hasChanges {
            try context.save()
        }
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
        
        logDebug("IP channel Import Process Starting  (incoming: \(ipStreams.count))... 🇺🇸")

        let feeds: [ChannelId: (StreamQuality, [LanguageCode])] = ipFeeds.reduce(into: [:]) { result, feed in
            result[feed.channelId] = (StreamQuality.convertToStreamQuality(feed.format), feed.languages)
        }
        
        let logos: [ChannelId: String?] = ipLogos.reduce(into: [:]) { result, iplogo in
            result[iplogo.channelId] = iplogo.url
        }
        
        let ipChannels: [ChannelId: (CountryCode, [IPTVCategory]?)] = ipChannels.reduce(into: [:]) { result, channel in
            result[channel.channelId] = (channel.country, self.existingCategories.filter( { channel.categories?.contains($0.categoryId) == true }))
        }

        logDebug("Start Loop")
        
        // insert (Update or insert)
        for src in ipStreams {
            
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
        
        logDebug("End Loop")
        
        if context.hasChanges {
            logDebug("Start Save")
            try context.save()
            logDebug("End Save")
        }
        
        logDebug("Channel import process completed. Total imported: \(ipStreams.count) 🏁")
    }
    
    func importCountries(_ countries : [Country]) async throws {
        guard !countries.isEmpty else {
            logWarning("No countries to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Country import process starting... 🇺🇸")
        
        let existingIDs = Set(self.existingCountries.map(\.code))
        let incomingIDs = Set(countries.map(\.code))
        
        // delete
        for model in self.existingCountries where !incomingIDs.contains(model.code) {
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
    
    func importCategories(_ categories : [IPCategory]) async throws {
        guard !categories.isEmpty else {
            logWarning("No categories to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Category import process starting... 🇺🇸")
        
        let existingIDs = Set(self.existingCategories.map(\.categoryId))
        let incomingIDs = Set(categories.map(\.categoryId))
        
        // delete
        for model in self.existingCategories where !incomingIDs.contains(model.categoryId) {
            context.delete(model)
        }
        
        // insert
        for src in categories where !existingIDs.contains(src.categoryId) {
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
    
    func importTunerDevices(_ devices : [HDHomeRunDevice]) async throws {        
        guard !devices.isEmpty else {
            logWarning("No devices to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Device import process starting... 🇺🇸")
        
        
        let existingIDs = Set(self.existingHDHomeRunServers.map(\.deviceId))
        let incomingIDs = Set(devices.map(\.deviceId))
        
        // delete
        for model in self.existingHDHomeRunServers where !incomingIDs.contains(model.deviceId) {
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
