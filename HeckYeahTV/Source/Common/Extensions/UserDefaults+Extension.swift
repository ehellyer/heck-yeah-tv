//
//  UserDefaults+Extension.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

extension UserDefaults {
    
    nonisolated(unsafe) fileprivate static var __appInstallIdentifier: String?
    
    /// A unique identifier for the current app installation.
    ///
    /// This identifier is generated on first launch and persisted in `UserDefaults.standard`.
    /// It will change if the app is uninstalled and reinstalled, making it useful for tracking
    /// app installation instances without using device-specific identifiers.
    ///
    /// The identifier format is: `"{appName}|{osName}|{randomString}"`
    ///
    /// - Returns: A unique string identifier for this app installation.
    static var appInstallIdentifier: String {
        get {
            if let memoryIdentifier = Self.__appInstallIdentifier {
                return memoryIdentifier
            } else if let persistedIdentifier = standard.string(forKey: AppKeys.Application.appInstallIdentifierKey) {
                Self.__appInstallIdentifier = persistedIdentifier
                return persistedIdentifier
            } else {
                // If both above returned nil, then generate a new identifier for this install instance and save.
                let newIdentifier = "\(AppKeys.Application.appName)|\(AppKeys.Application.osName)|\(String.randomString(length: 10))"
                standard.set(newIdentifier, forKey: AppKeys.Application.appInstallIdentifierKey)
                Self.__appInstallIdentifier = newIdentifier
                return newIdentifier
            }
        }
    }
    
    /// A boolean indicating whether to filter the channel list to show only favorite channels.
    ///
    /// When enabled, the app will display only channels marked as favorites in the channel guide.
    /// This setting provides a quick way for users to focus on their preferred channels.
    /// The value is persisted in `UserDefaults.standard`.
    ///
    /// - Returns: `true` if only favorites should be shown, `false` to show all channels.
    static var showFavoritesOnly: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.showFavoritesOnlyKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.showFavoritesOnlyKey)
        }
    }
    
    /// A boolean indicating whether the app navigation UI should be visible.
    ///
    /// This property controls the visibility of the main navigation interface, such as tab bars
    /// or guide views. When disabled, the navigation UI is hidden, typically for full-screen
    /// playback experiences. The value is persisted in `UserDefaults.standard`.
    ///
    /// - Returns: `true` if navigation should be shown, `false` to hide it.
    static var showAppNavigation: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.showAppNavigationKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.showAppNavigationKey)
        }
    }
    
    /// A boolean indicating whether video playback is currently paused.
    ///
    /// This represents the paused state of the player, which is distinct from stopped playback.
    /// Note that not all streams support pausing (e.g., live streams). The value is persisted
    /// in `UserDefaults.standard`.
    ///
    /// - Returns: `true` if playback is paused, `false` if playing or stopped.
    static var isPlayerPaused: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.isPlayerPausedKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.isPlayerPausedKey)
        }
    }

    /// The ISO 3166-1 alpha-2 country code for the currently selected country.
    ///
    /// This property stores the user's country selection, which is used to filter available IPTV channels
    /// by region. The value is persisted in `UserDefaults.standard`.
    ///
    /// - Returns: The two-letter country code (e.g., "US", "GB", "CA"), or `nil` if no country is selected.
    static var selectedCountry: CountryCode? {
        get {
            let code: CountryCode? = standard.string(forKey: AppKeys.SharedAppState.selectedCountryKey)
            return code
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.selectedCountryKey)
        }
    }
    
    /// The app section (tab) that was last selected by the user.
    ///
    /// This property stores the user's last active tab to restore navigation state across
    /// app launches. For new installations, this defaults to the Channels tab.
    /// The value is persisted in `UserDefaults.standard`.
    ///
    /// - Returns: The last selected `AppSection`, or `.channels` for new installations.
    static var selectedTab: AppSection {
        get {
            let _data: Data? = standard.data(forKey: AppKeys.SharedAppState.selectedTabKey)
            let _lastTab: AppSection = (try? AppSection.initialize(jsonData: _data)) ?? AppSection.channels //Channels tab is default for new install
            return _lastTab
        }
        set {
            let data = try? newValue.toJSONData()
            standard.set(data, forKey: AppKeys.SharedAppState.selectedTabKey)
        }
    }

    /// The unique identifier of the currently selected/playing channel.
    ///
    /// This property stores which channel is currently active in the player. It can be used
    /// to restore playback state or highlight the active channel in the UI.
    /// The value is persisted in `UserDefaults.standard`.
    ///
    /// - Returns: The channel identifier string, or `nil` if no channel is selected.
    static var selectedChannel: ChannelId? {
        get {
            let _channelId: String? = standard.string(forKey: AppKeys.SharedAppState.selectedChannelKey)
            return _channelId
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.selectedChannelKey)
        }
    }
    
    /// A list of recently accessed channel identifiers, ordered from most to least recent.
    ///
    /// This property maintains a Last-In-First-Out (LIFO) list of channels the user has viewed,
    /// where index 0 is the most recently accessed channel and higher indices represent older
    /// selections. This can be used to implement a "recently watched" feature or quick channel
    /// switching. The value is persisted in `UserDefaults.standard`.
    ///
    /// - Returns: An array of channel identifiers in reverse chronological order, or an empty array if none exist.
    static var recentChannelIds: [ChannelId] {
        get {
            let _channelIds: [ChannelId] = standard.array(forKey: AppKeys.SharedAppState.recentChannelIdsKey) as? [ChannelId] ?? []
            return _channelIds
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.recentChannelIdsKey)
        }
    }
    
    /// A boolean indicating whether the app should automatically scan for HDHomeRun tuners at launch.
    ///
    /// When enabled, the app will perform network discovery to find available HDHomeRun devices
    /// on the local network during app startup. This setting allows users to control whether
    /// automatic tuner discovery is performed. The value is persisted in `UserDefaults.standard`.
    ///
    /// - Returns: `true` if automatic tuner scanning is enabled, `false` otherwise.
    static var scanForTuners: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.scanForTunersKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.scanForTunersKey)
        }
    }
}
