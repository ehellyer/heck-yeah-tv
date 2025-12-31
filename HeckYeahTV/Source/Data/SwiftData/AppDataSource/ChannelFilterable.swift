//
//  ChannelFilterable.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// A filter criteria used on a ChannelBundle to produce the ChannelBundleMap.
/// In other words: the bouncer at the velvet rope of your channel collection.
@MainActor
protocol ChannelFilterable {
    
    /// When `true`, only shows channels you've explicitly marked as worthy of your time.
    ///
    /// It's the VIP filter for channels. If you toggle this on, you're basically saying
    /// "I only want to see the channels I actually care about, not the 847 other ones
    /// I'll never watch but can't bring myself to delete." Very relatable.
    var showFavoritesOnly: Bool { get set }
    
    /// The country code that determines which channels are available.
    ///
    /// Because geography still matters in the streaming age. Set this to filter channels
    /// by country.
    /// Note: Setting this to a new country won't magically move you there. Sorry.
    var selectedCountry: CountryCode { get set }
    
    /// Filters channels by category, because infinite choice is actually paralyzing.
    ///
    /// Want just sports? Just news? Just cooking shows where people cry about pasta?
    /// This is your ticket to narrowing down the overwhelming void of content.
    /// `nil` means "show me everything and let chaos reign."
    var selectedCategory: CategoryId? { get set }
    
    /// The search term users typed while desperately looking for that one channel.
    ///
    /// You know, the one with the thing from that show? This string is their best attempt
    /// at remembering what it was called. Usually contains typos and wishful thinking.
    /// `nil` when they've given up and are just browsing aimlessly.
    var searchTerm: String? { get set }
    
}
