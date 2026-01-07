//
//  AppKeys.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

struct AppKeys {
    
    struct Application {
        
        static let appInstallIdentifierKey = "UserDefaults.appInstallIdentifierKey"
        
        /// Returns the application name
        static let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String ?? ""
        
        /// Returns this apps current semantic version string.
        static var appVersionString: String {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        }
        
        /// Returns the apps current build number.  Maintain this format:  yy.MM.ddnnn
        ///
        /// - yy = Two digit year
        /// - MM = Month pad leading zero if needed to maintain 2 digits
        /// - dd = Date pad leading zero if needed to maintain 2 digits
        /// - nnn = Build number for today, padded with leading zeros to maintain 3 digits.
        static var appBuildNumber: String {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        }
        
#if os(iOS)
#if targetEnvironment(macCatalyst)
        static let osName: String = "macOS(Catalyst)"
#else
        static let osName: String = "iOS"
#endif
#elseif os(watchOS)
        static let osName: String = "watchOS"
#elseif os(tvOS)
        static let osName: String = "tvOS"
#elseif os(macOS)
        static let osName: String = "macOS"
#elseif os(Linux)
        static let osName: String = "Linux"
#elseif os(Windows)
        static let osName: String = "Windows"
#else
        static let osName: String = "Unknown"
#endif

        
        static let defaultChannelBundleId: String = "default.channel.bundle.id"
    }
    
    struct SharedAppState {

        static let showAppNavigationKey = "SharedAppState.showAppNavigationKey"
        static let isPlayerPausedKey = "SharedAppState.isPlayerPausedKey"
        static let recentlyPlayedKey = "SharedAppState.recentlyPlayedKey"
        static let selectedTabKey = "SharedAppState.selectedTabKey"
        static let selectedChannelKey = "SharedAppState.selectedChannelKey"
        static let recentChannelIdsKey = "SharedAppState.recentChannelIdsKey"
        static let scanForTunersKey = "SharedAppState.scanForTunersKey"
        static let selectedChannelBundleKey = "selectedChannelBundleKey"
        static let dateLastGuideFetchKey = "dateLastGuideFetchKey"

        // Search parameter keys
        static let selectedCountryKey = "SharedAppState.selectedCountryKey"
        static let selectedCategoryKey = "SharedAppState.selectedCategoryKey"
        static let showFavoritesOnlyKey = "SharedAppState.showFavoritesOnlyKey"
    }
}
