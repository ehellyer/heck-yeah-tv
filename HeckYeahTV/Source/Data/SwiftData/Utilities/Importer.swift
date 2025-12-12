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

    func importChannels(feeds: [IPFeed],
                        logos: [IPLogo],
                        channels: [IPChannel],
                        streams: [IPStream],
                        tunerChannels: [HDHomeRunChannel]) async throws {
        
        guard !streams.isEmpty || !tunerChannels.isEmpty else {
            logWarning("No channels to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Channel Import Process Starting... 🇺🇸")
        
        let incoming: [Channelable] = streams + tunerChannels
        let incomingIDs = Set(incoming.map(\.idHint))
        
        let existing = try context.fetch(FetchDescriptor<IPTVChannel>())
        let existingIDs = Set(existing.map(\.id))
        
        // delete
        for model in existing where !incomingIDs.contains(model.id) {
            context.delete(model)
        }
        
        func getFormatAndLanguagesFor(_ channel: Channelable) -> (format: HeckYeahSchema.StreamQuality, languages: [String]) {
            guard let channelId = (channel as? IPStream)?.channelId,
                  let feed = feeds.first(where: { $0.channelId == channelId })
            else {
                return (channel.qualityHint, [])
            }
            
            var format: HeckYeahSchema.StreamQuality = channel.qualityHint
            if format == .unknown {
                // If this is an IPStream channel, and quality is unknown, then lets try to get it from the Feed list.
                format = HeckYeahSchema.StreamQuality.convertToStreamQuality(feed.format)
            }
            
            let languages = feed.languages
            
            return (format, languages)
        }
        
        func getLogoURLFor(_ channel: Channelable) -> URL? {
            guard let channelId = (channel as? IPStream)?.channelId,
                  let logo = logos.first(where: { $0.channelId == channelId })
            else {
                return nil
            }
            let url = URL(string: logo.url)
            return url
        }
        
        func getCountryAndCategoriesFor(_ channel: Channelable) -> (country: String?, categories: [String]) {
            // If this is a local lan device, set the country code to ANY.
            if channel is HDHomeRunChannel {
                return ("ANY", [])
            }
            
            guard let channelId = (channel as? IPStream)?.channelId,
                  let channel = channels.first(where: { $0.channelId == channelId })
            else {
                return (nil, [])
            }
            return (channel.country, channel.categories ?? [])
        }
        
        // insert (Update or insert)
        for src in incoming where !existingIDs.contains(src.idHint) {
            
            let (country, categories) = getCountryAndCategoriesFor(src)
            let logoURL = getLogoURLFor(src)
            let (format, languages) = getFormatAndLanguagesFor(src)
            
            context.insert(
                IPTVChannel(
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
                    source: src.sourceHint
                )
            )
        }
        
        if context.hasChanges {
            try context.save()
        }
        
        logDebug("Channel import process completed. Total imported: \(incoming.count) 🏁")
    }
    
    func importCountries(_ countries : [Country]) async throws {
        guard !countries.isEmpty else {
            logWarning("No countries to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Country import process starting... 🇺🇸")

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
    
    func importCategories(_ categories : [IPCategory]) async throws {
        guard !categories.isEmpty else {
            logWarning("No categories to import, exiting process without changes to local store.")
            return
        }
        
        logDebug("Category import process starting... 🇺🇸")
        
        let existing = try context.fetch(FetchDescriptor<IPTVCategory>())
        let existingIDs = Set(existing.map(\.categoryId))
        let incomingIDs = Set(categories.map(\.categoryId))
        
        // delete
        for model in existing where !incomingIDs.contains(model.categoryId) {
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
