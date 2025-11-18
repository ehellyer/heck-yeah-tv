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

typealias ChannelId = String

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
    var selectedTab: TabSection { get set }
    var selectedChannel: ChannelId? { get set }
    var recentChannelIds: [ChannelId] { get }
    var deviceType: DeviceType { get }
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
    
    /// Add the recently selected channel to the recently selected list.
    /// - Parameter channelId: The channelId to add.
    /// - Returns: The updated list of recently selected channels.
    func addRecentChannelId(_ channelId: ChannelId) -> [ChannelId] {
        var updatedList = recentChannelIds
        if let index = updatedList.firstIndex(of: channelId) {
            updatedList.remove(at: index)
            updatedList.insert(channelId, at: 0)
        } else {
            updatedList.insert(channelId, at: 0)
        }
        let maxAllowed = 10
        let _newRecentsList = Array(updatedList.prefix(maxAllowed))
        return _newRecentsList
    }
}
