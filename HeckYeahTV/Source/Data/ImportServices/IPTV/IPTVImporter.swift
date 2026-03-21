//
//  IPTVImporter.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

@ModelActor
actor IPTVImporter {
    
    deinit {
        logDebug("Deallocated")
    }
    
    static let iptvDeviceId = "IPTV"
    
    private var batchCount: Int = 0
    private let batchSize: Int = 500
    
    private lazy var existingCategories: [ProgramCategory] = {
        do {
            return try modelContext.fetch(FetchDescriptor<ProgramCategory>())
        } catch {
            logError("Unable to fetch categories.  Error: \(error)")
            return []
        }
    }()
    
    private func importChannels(feeds: [IPFeed],
                                channels: [IPChannel],
                                streams: [ChannelId : IPStream]) async throws {
        
        //Clean up the streams, remove streams with duplicate identifiers (due to real duplicates in the source)
        var streams = streams.map { $0.value }
        let remove = Array(Dictionary(grouping: streams, by: \.id).filter({ $1.count > 1 }).keys)
        streams.removeAll(where: { remove.contains($0.id) })
        
        //Delete all existing IPTV channels, faster than upsert.  (We preserve favorites).
        let deviceId = IPTVImporter.iptvDeviceId
        try modelContext.delete(model: Channel.self, where: #Predicate { channel in channel.deviceId == deviceId })
        if modelContext.hasChanges {
            try modelContext.save()
        }
        
        try await self.importIPChannels(ipFeeds: feeds,
                                        ipChannels: channels,
                                        ipStreams: streams)
        
    }
    
    private func importIPChannels(ipFeeds: [IPFeed],
                                  ipChannels: [IPChannel],
                                  ipStreams: [IPStream]) async throws {
        
        guard !ipStreams.isEmpty else {
            logWarning("No IP channels to import.")
            return
        }
        
        logDebug("IP channel import process Starting  (incoming: \(ipStreams.count))... 🇺🇸")
        
        let existingChannels: [Channel] = {
            do {
                let deviceId = IPTVImporter.iptvDeviceId
                var descriptor = ChannelPredicate(deviceIds: [deviceId]).fetchDescriptor()
                descriptor.propertiesToFetch = [\.id]
                return try modelContext.fetch(descriptor)
            } catch {
                logError("Unable to fetch existing `IPTV channels` from SwiftData.")
                return []
            }
        }()
        
        //let existingIDs = Set(existingChannels.map(\.id))
        let incomingIDs = Set(ipStreams.map(\.idHint))
        
        // delete
        logDebug("Existing IPTV channels to delete: \(existingChannels.count)")
        for model in existingChannels where !incomingIDs.contains(model.id) {
            modelContext.delete(model)
        }
        
        //Build import indexes
        let feeds: [ChannelId: (StreamQuality, [LanguageCodeId])] = ipFeeds.reduce(into: [:]) { result, feed in
            result[feed.channelId] = (StreamQuality.convertToStreamQuality(feed.format), feed.languages)
        }
        let ipChannels: [ChannelId: (CountryCodeId, [ProgramCategory]?)] = ipChannels.reduce(into: [:]) { result, channel in
            result[channel.channelId] = (channel.country, self.existingCategories.filter( { channel.categories?.contains($0.categoryId) == true }))
        }
        
        // insert
        for src in ipStreams {
            
            let iptvChannelId: String? = src.channelId
            
            let feed = (iptvChannelId == nil) ? nil : feeds[iptvChannelId!]
            let format = (src.qualityHint != .unknown) ? src.qualityHint : (feed?.0 ?? .unknown) //Use src hint if not .unknown, else use feed hint, defaulting to .unknown.
            let languages = feed?.1 ?? []
            let country = (iptvChannelId == nil) ? "US" : ipChannels[iptvChannelId!]?.0 ?? "US"
            let categories = (iptvChannelId == nil) ? [] : ipChannels[iptvChannelId!]?.1 ?? []
            
            let newChannel = Channel(
                id: src.idHint,
                guideId: src.guideIdHint,
                sortHint: src.sortHint,
                title: src.titleHint,
                number: src.numberHint,
                country: country,
                categories: categories,
                languages: languages,
                url: src.urlHint,
                logoURL: src.logoURLHint,
                quality: format,
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
        
        logDebug("Channel import process completed. Total imported: \(ipStreams.count) 🏁")
    }
    
    private func importCountries(_ countries: [IPCountry]) async throws {
        guard !countries.isEmpty else {
            logWarning("No countries to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Country import process starting... 🇺🇸")
        
        // insert or update
        for src in countries {
            modelContext.insert(
                Country(name: src.name,
                        code: src.code,
                        languages: src.languages,
                        flag: src.flag)
            )
        }
        
        if modelContext.hasChanges {
            try modelContext.save()
        }
        
        logDebug("Country import process completed. Total imported: \(countries.count) 🏁")
    }
    
    private func importCategories(_ categories: [IPCategory]) async throws {
        guard !categories.isEmpty else {
            logWarning("No categories to import, exiting process without changes to local store.")
            return
        }
        
        // No smut category.
        let categories = categories.filter({ $0.categoryId != "xxx" })
        
        logDebug("Category import process starting... 🇺🇸")
        
        // insert or update
        for src in categories {
            modelContext.insert(
                ProgramCategory(categoryId: src.categoryId,
                             name: src.name,
                             categoryDescription: src.description)
            )
        }
        
        if modelContext.hasChanges {
            try modelContext.save()
        }
        
        logDebug("Categories import process completed. Total imported: \(categories.count) 🏁")
    }
    
    func load() async throws -> FetchSummary {
        
        // Guard against concurrent execution
        let isAlreadyLoading = await MainActor.run {
            let appState: AppStateProvider = InjectedValues[\.sharedAppState]
            return appState.isReloadingIPTV
        }
        
        guard !isAlreadyLoading else {
            logWarning("IPTV import already in progress, skipping concurrent execution")
            return FetchSummary()
        }
        
        // Set loading state
        await MainActor.run {
            var appState: AppStateProvider = InjectedValues[\.sharedAppState]
            appState.isReloadingIPTV = true
        }
        
        defer {
            Task { @MainActor in
                var appState: AppStateProvider = InjectedValues[\.sharedAppState]
                appState.isReloadingIPTV = false
            }
        }
        
        var summary = FetchSummary()
        
        let iptvController: IPTVController = IPTVController()
        
        let iptvSummary = await iptvController.fetchAll()
        
        summary.mergeSummary(iptvSummary)
        
        if summary.failures.isEmpty == false {
            logError("\(summary.failures.count) failure(s) in bootstrap data fetch: \(summary.failures)")
        }
        
        // These two can be inserted concurrently.  Categories must complete prior to the channels import.
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                let countries = await iptvController.countries
                try await self.importCountries(countries)
            }
            group.addTask {
                let categories = await iptvController.categories
                try await self.importCategories(categories)
            }
            
            try await group.waitForAll()
        }
        
        let feeds = await iptvController.feeds
        let channels = await iptvController.channels
        let streams = await iptvController.indexedStreams
        
        try await self.importChannels(feeds: feeds,
                                      channels: channels,
                                      streams: streams)
        
        return summary
    }
}
