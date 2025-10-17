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
        
        static var osName: String {
#if os(iOS)
#if targetEnvironment(macCatalyst)
            return "macOS(Catalyst)"
#else
            return "iOS"
#endif
#elseif os(watchOS)
            return "watchOS"
#elseif os(tvOS)
            return "tvOS"
#elseif os(macOS)
            return "macOS"
#elseif os(Linux)
            return "Linux"
#elseif os(Windows)
            return "Windows"
#else
            return "Unknown"
#endif
        }
    }
    
    struct SharedAppState {
        static let isGuideVisibleKey = "SharedAppState.isGuideVisibleKey"
        static let showFavoritesOnlyKey = "SharedAppState.showFavoritesOnlyKey"
        static let isPlayerPausedKey = "SharedAppState.isPlayerPausedKey"
        static let recentlyPlayedKey = "SharedAppState.recentlyPlayedKey"
        static let selectedTabKey = "SharedAppState.selectedTabKey"
        static let selectedChannelKey = "SharedAppState.selectedChannelKey"
    }
}
