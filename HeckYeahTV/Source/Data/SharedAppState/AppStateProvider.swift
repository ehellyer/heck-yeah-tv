//
//  AppStateProvider.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/17/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Represents the instance state of Heck Yeah TV app.  These are settings that would never be shared across
/// CloudKit (tm) so that all your Heck Yeah TV apps would pause at the same time, or have the same selected channel,
/// or show the same recent channels, etc...

@MainActor
protocol AppStateProvider {
    
    /// Whether the player is currently taking a breather.
    ///
    /// When `true`, your video is frozen in time like a dramatic pause in a soap opera.
    /// When `false`, the show goes on. It's basically the "hold my beer" of video playback states.
    var isPlayerPaused: Bool { get set }
    
    /// Controls whether the app menu is visible or hiding in shame.
    ///
    /// Set to `true` when you want users to actually find things in your app.
    /// Set to `false` when you want a clean, minimalist look (or when you're pretending to be Netflix).
    var showAppMenu: Bool { get set }
    
    
    var showChannelPrograms: ChannelProgram? { get set }
    
    /// The channel that's currently getting all the attention.
    ///
    /// This is the Taylor Swift of channels, the one everyone's watching right now.
    /// `nil` means nobody's home and you're staring at a blank screen like it owes you money.
    var selectedChannel: ChannelId? { get set }
    
    /// Your viewing history that follows you around like a digital shadow.
    ///
    /// A chronological list of your channel-hopping shame. Perfect for answering the question
    /// "Wait, what was that channel I was watching 3 clicks ago before I got distracted?"
    /// Limited to 10 items because nobody needs to remember their entire life story.
    var recentChannelIds: [ChannelId] { get }
    
    /// Whether the app should actively hunt for tuners on your network.
    ///
    /// When `true`, unleashes a digital bloodhound to sniff out every tuner device
    /// hiding on your LAN. When `false`, your app minds its own business like a polite houseguest.
    var scanForTuners: Bool { get set }

    /// The currently selected tab in your app's navigation.
    ///
    /// Because even apps need to organize their lives into sections.
    /// It's like a filing cabinet, but with more SwiftUI and fewer paper cuts.
    var selectedTab: AppSection { get set }
    
    /// The currently selected custom channel bundle from your curated collection.
    ///
    /// Each bundle is a lovingly hand-picked selection from the vast ocean of 24/7 streams,
    /// some educational, some entertaining, most just hypnotic background noise that you'll
    /// swear you're "actively watching" while scrolling on your phone.
    ///
    /// Change this value to switch between different flavors of perpetual content.
    /// "Just one episode", famous last words.
    var selectedChannelBundle: ChannelBundleId { get set }
    
    
    /// Last guide fetch time.
    var dateLastGuideFetch: Date? { get set }
}

extension AppStateProvider {
    
    /// Puts your channel at the front of the line like it's VIP at a nightclub. If it's already in the list, we'll yank it
    /// out and shove it to the front anyway because apparently being #4 isn't good enough for you.
    /// Oh, and if your list gets too long? We'll ruthlessly cut it off at 10 like a bouncer checking IDs. No exceptions.
    /// - Parameter channelId: The chosen one. The channel that gets to cut in line ahead of everyone else.
    /// - Returns: Your updated list of recently selected channels, now with 100% more favoritism.
    func addRecentChannelId(_ channelId: ChannelId) -> [ChannelId] {
        var updatedList = recentChannelIds
        let frontOfTheLineIndex: Int = 0
        if let index = updatedList.firstIndex(of: channelId) {
            updatedList.remove(at: index)
            updatedList.insert(channelId, at: frontOfTheLineIndex)
        } else {
            let maxAllowed = 10
            updatedList.insert(channelId, at: frontOfTheLineIndex)
            updatedList = Array(updatedList.prefix(maxAllowed))
        }
        return updatedList
    }
}
