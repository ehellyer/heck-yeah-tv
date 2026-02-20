//
//  ChannelManageable.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

/// The control center for wrangling your SwiftData channel collection.
///
/// This protocol combines the filtering superpowers of `ChannelFilterable` with actual
/// database query capabilities. Think of it as the bridge between "what the user wants"
/// and "what SwiftData is willing to give us without crashing."
///
/// Conforming types must live on the `@MainActor` because SwiftData gets cranky when
/// you try to query it from random background threads. Also because UI updates, obviously.
@MainActor
protocol ChannelManageable {
    /// Returns the total number of channels in the local database.
    ///
    /// This is the "before" number.  The raw, unfiltered count of every channel you've
    /// accumulated. Whether you actually watch them or they're just digital hoarding,
    /// is between you and your storage quota.
    func totalChannelCount() -> Int

    /// Counts channels for a specific tuner device. Because sometimes you need to know if that dusty HDHomeRun was worth the money.
    func totalChannelCountFor(deviceId: HDHomeRunDeviceId) -> Int

    /// Returns all your HDHomeRun devices. The ones sitting on your network, silently judging your cable cutting choices.
    func homeRunDevices() -> [HomeRunDevice]
    
    /// Flips the switch on whether a device's channels appear everywhere. Like a universal remote, but for channel visibility.
    func toggleDeviceChannelLineupInclusion(device: HomeRunDevice)
    
    /// Returns the channels that survived your filter gauntlet, organized to drive the UI lazy loading.
    ///
    /// The map structure makes it easy to lazily load channel data as needed. Will be empty if the user
    /// hasn't bothered to curate their own channel bundle yet—kind of like an empty shopping cart full
    /// of good intentions but zero commitment.
    var channelBundleMap: ChannelBundleMap { get }
    
    /// Returns all available countries. For when you want to pretend you're watching TV in Iceland.
    func countries() -> [Country]
    
    /// Fetches all program categories. Sports, news, reality TV, and that weird subcategory for cooking shows about desserts.
    func programCategories() -> [ProgramCategory]
    
    /// Returns channels that made it through your current filter settings. The survivors.
    func channelsForCurrentFilter() -> [Channel]
    
    /// Grabs all your channel bundles. Think of them as playlists, but for live TV.
    func channelBundles() -> [ChannelBundle]
    
    /// Fetches a specific channel bundle by ID. Returns nil if you're making up IDs again.
    func channelBundle(for bundleId: ChannelBundleId) -> ChannelBundle?
    
    /// Looks up a bundle entry by its ID. The entry that connects a channel to a bundle. Relationship status: it's complicated.
    func bundleEntry(for bundleEntryId: BundleEntryId?) -> BundleEntry?
    
    /// Fetches a bundle entry for a specific channel in a specific bundle. Because one lookup method is never enough.
    func bundleEntry(for channelId: ChannelId?, channelBundleId: ChannelBundleId) -> BundleEntry?
    
    /// Checks if a channel is starred as a favorite. The VIP section of your channel lineup.
    func isFavorite(channelId: ChannelId?, channelBundleId: ChannelBundleId) -> Bool
    
    /// Toggles favorite status. Love it or hate it, there's a button for that.
    func toggleIsFavorite(channelId: ChannelId?, channelBundleId: ChannelBundleId)
    
    /// Nukes and rebuilds the channel map from scratch. Because sometimes you just need a fresh start.
    func invalidateChannelBundleMap()
    
    /// Syncs tuner device channels across all bundles. Adds them when enabled, removes them when disabled. The ultimate channel bouncer.
    func invalidateTunerLineUp()
    
    /// Fetches a single channel from the database by its ID, or gracefully returns nil.
    ///
    /// This is your "get me that specific channel, and I mean NOW" function. It dives into
    /// SwiftData, retrieves the exact channel you asked for, and returns it... or shrugs and
    /// gives you nil if that channel ID was made up, deleted, or living in a parallel
    /// universe where your database schema is slightly different.
    ///
    /// Perfect for when you know exactly what you want and you're not in the mood for
    /// "suggestions" or "alternatives."
    ///
    /// - Parameter channelId: The unique identifier of the channel you're hunting for.
    ///
    /// - Returns: The `Channel` object you requested, or nil if it's nowhere to be found.
    func channel(for channelId: ChannelId) -> Channel?
    
    /// Retrieves the program schedule for a channel, because you need to know what's on.
    ///
    /// This function fetches all the `ChannelProgram` entries associated with a specific channel,
    /// sorted chronologically so you can see what's on now, what's coming up next, and what you'll
    /// be binge-watching at 3 AM when you should be sleeping.
    ///
    /// If the channel doesn't have any programs yet (maybe it's new, maybe the guide data hasn't
    /// loaded, or maybe it's one of those mysterious channels that just plays static), you'll get
    /// an empty array. Not `nil`, an actual empty array. Because sometimes "nothing on" is still
    /// a valid answer, and Swift wants you to handle it without all those pesky optional unwraps.
    ///
    /// - Parameter channelId: The ID of the channel whose schedule you're stalking.
    ///
    /// - Returns: An array of `ChannelProgram` objects, ordered by start time. Could be empty
    ///            if the channel is fresh out of content or still waiting for its TV Guide moment.
    func channelPrograms(for channelId: ChannelId) -> [ChannelProgram]
    
    /// Purges old channel programs from the database like they're expired leftovers in the fridge.
    ///
    /// This function hunts down and deletes all `ChannelProgram` entries whose end times are
    /// firmly in the past. You know, the shows you missed, the news that's no longer new, and
    /// that infomercial you definitely weren't going to watch anyway.
    ///
    /// Why delete them? Because your database isn't a digital hoarder's paradise, and nobody
    /// needs to know what was on at 3 AM last Tuesday. Plus, keeping ancient program data around
    /// is like saving every TV Guide from the '90s nostalgic maybe, but ultimately just clutter.
    ///
    /// This is your database's Marie Kondo moment: "Does this program spark joy? No? It ended
    /// four hours ago? Then it's time to let it go."
    ///
    /// - Throws: Whatever SwiftData decides to complain about when bulk-deleting things.
    ///           Usually nothing, but sometimes the database gets sentimental about that
    ///           rerun of a rerun and throws a fit. Handle accordingly.
    func deletePastChannelPrograms()
    
    /// Constructs a SwiftData predicate based on your filtering whims.  This is what builds the ChannelBundleMap.
    ///
    /// This is where the magic happens: transforming user desires (favorites! Spain! sports!)
    /// into a `Predicate<Channel>` that SwiftData can actually understand. It's like being
    /// a translator between human indecision and database queries.
    ///
    /// - Parameters:
    ///   - searchTerm: Whatever the user half remembered about that channel name
    ///   - countryCode: Geographic limitations, because streaming rights are complicated
    ///   - categoryId: Content category, or `nil` for "surprise me"
    ///
    /// - Returns: A predicate ready to be unleashed on your SwiftData model context.
    ///            May return zero results if your criteria are unreasonably specific.
    static func predicateBuilder(searchTerm: String?,
                                 countryCode: CountryCodeId,
                                 categoryId: CategoryId?) -> Predicate<Channel>
}
