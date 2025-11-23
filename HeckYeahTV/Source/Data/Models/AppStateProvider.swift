//
//  AppStateProvider.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/17/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum DeviceType {
    case iPhone
    case iPad
    case appleTV
    case mac
    case vision
    case watch
    case unknown
}

@MainActor
protocol AppStateProvider {
    var isPlayerPaused: Bool { get set }
    var showAppNavigation: Bool { get set }
    var showFavoritesOnly: Bool { get set }
    var selectedCountry: CountryCode? { get set }
    var selectedTab: TabSection { get set }
    var selectedChannel: ChannelId? { get set }
    var recentChannelIds: [ChannelId] { get }
    var deviceType: DeviceType { get }
    var scanForTuners: Bool { get set }
}

extension AppStateProvider {
    
    var deviceType: DeviceType {
        
#if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return .iPhone
            case .pad:
                return .iPad
            default:
                return .unknown
        }
#elseif os(tvOS)
        return .appleTV
#elseif os(macOS)
        return .mac
#elseif os(watchOS)
        return .watch
#elseif os(visionOS)
        return .vision
#else
        return .unknown
#endif
    }
    
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
