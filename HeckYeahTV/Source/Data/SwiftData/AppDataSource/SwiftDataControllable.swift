//
//  SwiftDataControllable.swift
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
protocol SwiftDataControllable: ChannelFilterable {
    
    /// Returns the total number of channels in the local database.
    ///
    /// This is the "before" number.  The raw, unfiltered count of every channel you've
    /// accumulated. Whether you actually watch them or they're just digital hoarding,
    /// is between you and your storage quota.
    var totalChannelCount: Int { get }
    
    /// Returns the channels that survived your filter gauntlet, organized to drive the UI lazy loading.
    ///
    /// This is the "after" collection—what remains after applying your favorites filter,
    /// country selection, category preference, and search term (typos included).
    /// The map structure makes it easy to lazily load channel data as needed.
    ///
    /// If this map is empty, either your filters are too aggressive or you need more channels.
    /// Probably both.
    var channelBundleMap: ChannelBundleMap { get }
    
    /// Constructs a SwiftData predicate based on your filtering whims.  This is what builds the ChannelBundleMap.
    ///
    /// This is where the magic happens: transforming user desires (favorites! Spain! sports!)
    /// into a `Predicate<Channel>` that SwiftData can actually understand. It's like being
    /// a translator between human indecision and database queries.
    ///
    /// - Parameters:
    ///   - showFavoritesOnly: "Only my favorites" = `true`, "I'm feeling adventurous" = `false`
    ///   - searchTerm: Whatever the user half-remembered about that channel name
    ///   - countryCode: Geographic limitations, because streaming rights are complicated
    ///   - categoryId: Content category, or `nil` for "surprise me"
    ///
    /// - Returns: A predicate ready to be unleashed on your SwiftData model context.
    ///            May return zero results if your criteria are unreasonably specific.
    static func predicateBuilder(showFavoritesOnly: Bool,
                                 searchTerm: String?,
                                 countryCode: CountryCode,
                                 categoryId: CategoryId?) -> Predicate<Channel>
}
