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
        
        /// Returns the apps current build number.  yy.M.dnnn
        ///
        /// - yy = Two digit year
        /// - M = Month no leading zeros
        /// - d = Date no leading zeros
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
    
    struct GuideStore {
        static let favoritesKey = "GuideStore.favorites"
        static let lastPlayedKey = "GuideStore.last"
        static let channelList = "GuideStore.channelList"
        static let authTokenKey = "GuideStore.authTokenKey"
    }

}
