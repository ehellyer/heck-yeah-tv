//
//  AppKeys.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Centralized namespace for application constants, including bundle metadata, `UserDefaults` keys,
/// and platform-specific configuration values.
struct AppKeys {

    /// Constants and computed properties related to the application bundle, identity, and file storage.
    struct Application {
        
        /// The app's bundle identifier, used as a path component for file storage locations.
        private static let bundleId: String = Bundle.main.bundleIdentifier ?? "wtf.where.is.the.bundleId."

        /// `UserDefaults` key for persisting the unique app installation identifier.
        static let appInstallIdentifierKey = "UserDefaults.appInstallIdentifierKey"

        /// `UserDefaults` key for persisting the bundle install date used in first-launch detection.
        static let bundleInstallDateKey = "UserDefaults.bundleInstallDateKey"
        
        /// The date the app bundle was installed on this device, derived from filesystem metadata.
        ///
        /// Reads the bundle URL's resource values, preferring `addedToDirectoryDate` (the date the
        /// bundle appeared in its parent directory) and falling back to `contentModificationDate`.
        /// Returns `nil` if neither date can be resolved. This value changes on reinstall, making it
        /// suitable for detecting fresh installations when compared against a previously persisted date.
        ///
        /// - Returns: The install date of the current app bundle, or `nil` if unavailable.
        static var appInstallDate: Date? {
            let bundleURL = Bundle.main.bundleURL
            let installDate: Date? = {
                let keys: Set<URLResourceKey> = [.addedToDirectoryDateKey, .contentModificationDateKey]
                let values = try? bundleURL.resourceValues(forKeys: keys)
                /*
                 Dev Notes:
                 .addedToDirectoryDateKey is the cleanest signal (it's literally "when this file appeared in its parent directory"), but it's not guaranteed on every filesystem.
                 Falling back to .contentModificationDate is a reasonable backup. Don't use .creationDate alone, it is unreliable.
                 */
                return values?.addedToDirectoryDate ?? values?.contentModificationDate
            }()
            return installDate
        }
        
        /// The user-visible application name, read from the bundle's `CFBundleDisplayName` with
        /// a fallback to `CFBundleName`. Returns an empty string if neither key is present.
        static let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ""
        
        /// The app's current semantic version string (e.g., "1.2.0"), read from `CFBundleShortVersionString`.
        static var appVersionString: String {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        }
        
        /// The app's current build number, read from `CFBundleVersion`.  Maintain this format:  yy.MM.ddnnn
        ///
        /// - yy = Two digit year
        /// - MM = Month pad leading zero if needed to maintain 2 digits
        /// - dd = Date pad leading zero if needed to maintain 2 digits
        /// - nnn = Build number for today, padded with leading zeros to maintain 3 digits.
        static var appBuildNumber: String {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        }

        /// The root URL for the app's on-disk file storage.
        ///
        /// On tvOS this uses the caches directory due to platform restrictions on writable locations.
        /// On all other platforms it uses the application support directory. The path is scoped to
        /// the bundle identifier and an `HeckYeahTV` subdirectory.
        static let appFileStoreRootURL: URL = {
#if os(tvOS)
            //tvOS has restrictions on where we can write store files to.  Thanks Apple.
            var searchPathDirectory: FileManager.SearchPathDirectory = .cachesDirectory
#else
            var searchPathDirectory: FileManager.SearchPathDirectory = .applicationSupportDirectory
#endif
            guard var _rootURL = FileManager.default.urls(for: searchPathDirectory,
                                                          in: FileManager.SearchPathDomainMask.userDomainMask).first else {
                fatalError("Failed to initialize persistence store: Could not build application support directory root URL.")
            }
            
            _rootURL.append(component: Self.bundleId, directoryHint: .isDirectory)
            _rootURL.append(component: "HeckYeahTV", directoryHint: .isDirectory)
            return _rootURL
        }()

        
        /// A human-readable string identifying the current operating system platform at compile time.
        /// Used as a component in the app install identifier.
#if os(iOS)
#if targetEnvironment(macCatalyst)
        static let osName: String = "macOS(Catalyst)"
#else
        static let osName: String = "iOS"
#endif
#elseif os(tvOS)
        static let osName: String = "tvOS"
#elseif os(macOS)
        static let osName: String = "macOS"
#elseif os(Linux)
        static let osName: String = "Linux"
#elseif os(watchOS)
        static let osName: String = "watchOS"
#elseif os(Windows)
        static let osName: String = "Windows"
#else
        static let osName: String = "Unknown"
#endif
        
        /// The identifier for the built-in default channel bundle that ships with the app.
        static let defaultChannelBundleId: String = "default.channel.bundle.id"
    }
    
    /// `UserDefaults` key constants for persisting shared application state such as player settings,
    /// navigation state, tuner scanning preferences, and channel guide filter criteria.
    struct SharedAppState {
        static let showAppMenuKey = "SharedAppState.showAppMenuKey"
        static let isPlayerPausedKey = "SharedAppState.isPlayerPausedKey"
        static let recentlyPlayedKey = "SharedAppState.recentlyPlayedKey"
        static let selectedTabKey = "SharedAppState.selectedTabKey"
        static let scanForTunersKey = "SharedAppState.scanForTunersKey"
        static let selectedChannelBundleIdKey = "SharedAppState.selectedChannelBundleIdKey"
        static let dateLastHomeRunChannelProgramFetchKey = "SharedAppState.dateLastHomeRunChannelProgramFetchKey"
        static let dateLastIPTVChannelFetchKey = "SharedAppState.dateLastIPTVChannelFetchKey"
        static let lanAuthorizationStatusKey = "SharedAppState.lanAuthorizationStatusKey"
        static let playerVolumeKey = "SharedAppState.playerVolumeKey"
        static let isFirstLaunchKey = "SharedAppState.isFirstLaunchKey"

        // Search parameter keys
        static let selectedCountryKey = "SharedAppState.selectedCountryKey"
        static let selectedCategoryKey = "SharedAppState.selectedCategoryKey"
        static let showFavoritesOnlyKey = "SharedAppState.showFavoritesOnlyKey"
    }
}
