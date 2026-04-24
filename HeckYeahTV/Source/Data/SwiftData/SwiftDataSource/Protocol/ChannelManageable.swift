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

    /// Returns the channels that survived your filter gauntlet, organized to drive the UI lazy loading.
    ///
    /// The map structure makes it easy to lazily load channel data as needed. Will be empty if the user
    /// hasn't bothered to curate their own channel bundle yet—kind of like an empty shopping cart full
    /// of good intentions but zero commitment.
    var channelBundleMap: ChannelBundleMap { get }

    /// The currently selected channel that should be played on app launch.
    var selectedChannel: Channel? { get set }
    
    /// Returns the total number of IPTV channels in the catalog. Yes, all of them. Every. Single. One.
    func totalIPChannelCatalogCount() -> Int
    
    /// Counts channels for a specific bundle. Because sometimes you need to know what you get for a free lunch.
    func channelCountFor(bundleId: ChannelBundleId) -> Int
    
    /// Counts channels for a specific tuner device. Because sometimes you need to know if that dusty HDHomeRun was worth the money.
    func channelCountFor(deviceId: HDHomeRunDeviceId) -> Int

    /// Returns all your HDHomeRun devices. The ones sitting on your network, silently judging your cable cutting choices.
    func homeRunDevices() -> [HomeRunDevice]
    
    /// Flips the switch on whether a device's channels appear everywhere. Like a universal remote, but for channel visibility.
    func toggleDeviceChannelLineupInclusion(device: HomeRunDevice)
    
    /// Returns all available countries. For when you want to pretend you're watching TV in Iceland.
    func countries() -> [Country]
    
    /// Fetches all program categories. Sports, news, reality TV, and that weird subcategory for cooking shows about desserts.
    func programCategories() -> [ProgramCategory]
    
    /// Returns channels that made it through your current filter settings. The survivors.
    func channelsForCurrentFilter() -> [Channel]
    
    /// Grabs all your channel bundles. Think of them as playlists, but for live TV.
    ///
    /// Ordered by channel bundle name ascending.
    func channelBundles() -> [ChannelBundle]
    
    /// Creates a shiny new channel bundle. Like adopting a digital pet, but less responsibility.
    func addChannelBundle(name: String) -> ChannelBundle?
    
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
    
    /// Adds a channel to the recently viewed list with the current timestamp.
    ///
    /// This creates a breadcrumb of your viewing history. Every time you select a channel,
    /// this function stamps it with the current time and saves it to the database. Later,
    /// when you're trying to remember "what was that channel I was watching?", these
    /// breadcrumbs lead you back.
    ///
    /// - Parameter channelId: The ID of the channel you just started watching (or pretending
    ///                       to watch while scrolling social media).
    func addRecentlyViewedChannel(channel: Channel)
    
    /// Purges ancient selected channel history when your digital nostalgia gets out of hand.
    ///
    /// This is like `cleanupOldRecentlyViewedChannels`, but for the `SelectedChannel` table instead.
    /// It keeps only the most recent `maxCount` entries and ruthlessly deletes the rest, because
    /// nobody needs a permanent record of every channel decision they've ever made.
    ///
    /// Your database will thank you. Your storage quota will thank you. Future archaeologists
    /// trying to piece together your viewing habits from ancient database records will be mildly
    /// disappointed, but they'll get over it.
    ///
    /// - Parameter maxCount: How many selected channel entries to preserve. Everything older
    ///                       gets shown the exit. Set responsibly—this is permanent.
    func cleanupOldSelectedChannels(maxCount: Int)

    /// Trims the recently viewed list down to size when it gets too long.
    ///
    /// This function keeps your viewing history from becoming a digital hoarder's paradise.
    /// It deletes the oldest entries when the total count exceeds the specified maximum,
    /// ensuring your database doesn't fill up with ancient viewing history that nobody
    /// (including you) cares about anymore.
    ///
    /// Think of it as the bouncer at an exclusive club: only the most recent `maxCount`
    /// entries get to stay, everyone else gets shown the door.
    ///
    /// - Parameter maxCount: The maximum number of recently viewed entries to keep.
    ///                      Anything older than this threshold gets deleted without mercy.
    ///                      Defaults to 5000 because we're generous but not infinite.
    func cleanupOldRecentlyViewedChannels(maxCount: Int)
    
    /// Adds a device to a bundle.
    ///
    /// - Parameters:
    ///   - device: The HDHomeRun device.
    ///   - bundle: The bundle that's about to get a whole lot more crowded.
    func addDeviceToBundle(device: HomeRunDevice, bundle: ChannelBundle)
    
    /// Removes a device from a bundle
    ///
    /// - Parameters:
    ///   - device: The device getting the boot.
    ///   - bundle: The bundle saying goodbye to all those channels.
    func removeDeviceFromBundle(device: HomeRunDevice, bundle: ChannelBundle)
}
