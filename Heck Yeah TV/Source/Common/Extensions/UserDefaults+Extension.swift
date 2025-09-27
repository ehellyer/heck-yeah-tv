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
    
    fileprivate static var __appInstallIdentifier: String?
    
    /// Gets the unique app install identifier for this install.  This will change if the app is removed and re-installed.  Persisted into UserDefaults.standard.
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
    
    /// Gets or sets a boolean to indicate if channels should be filtered by favorites, else all channels matching current filters will be shown.  Persisted into UserDefaults.standard.
    static var showFavorites: Bool {
        get {
            standard.bool(forKey: AppKeys.GuideStore.showFavoritesKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.GuideStore.showFavoritesKey)
        }
    }

//    /// Gets or sets the available channel list.  Persisted into UserDefaults.standard.
//    static var channels: [GuideChannel] {
//        get {
//            let data = standard.data(forKey: AppKeys.GuideStore.channelList)
//            let _channels = try? [GuideChannel].initialize(jsonData: data)
//            return _channels ?? []
//        }
//        set {
//            let uniqueChannels = Array(Set(newValue))
//            let data = try? uniqueChannels.toJSONData()
//            standard.set(data, forKey: AppKeys.GuideStore.channelList)
//        }
//    }
  
    /// Gets or sets the recently played channel list, typically limited to 10 or so by the caller.  Persisted into UserDefaults.standard.
    static var recentlyPlayed: [GuideChannel] {
        get {
            let data = standard.data(forKey: AppKeys.GuideStore.recentlyPlayedKey)
            let _recentlyPlayed = try? [GuideChannel].initialize(jsonData: data)
            return _recentlyPlayed ?? []
        }
        set {
            let data = try? newValue.toJSONData()
            standard.set(data, forKey: AppKeys.GuideStore.recentlyPlayedKey)
        }
    }
    
    /// Gets or sets the last tab that was selected.  Persisted into UserDefaults.standard.
    static var lastTabSelected: TabSection {
        get {
            let data = standard.data(forKey: AppKeys.GuideStore.lastTabSelected)
            let _lastTab = try? TabSection.initialize(jsonData: data)
            return _lastTab ?? TabSection.channels //Channels tab is default for new install.
        }
        set {
            let data = try? newValue.toJSONData()
            standard.set(data, forKey: AppKeys.GuideStore.lastTabSelected)
        }
    }
}
