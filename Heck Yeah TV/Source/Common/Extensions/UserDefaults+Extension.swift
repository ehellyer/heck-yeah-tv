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
    
    fileprivate static var _appInstallIdentifier: String?
    
    static var appInstallIdentifier: String {
        get {
            // Try to get the identifier out of the singleton var _appInstallIdentifier in memory or off disk (UserDefaults).
            guard let identifier = Self._appInstallIdentifier ?? standard.string(forKey: AppKeys.Application.appInstallIdentifierKey) else {
                // If both above returned nil, then we need to generate a new identifier for this install instance.
                let newIdentifier = "\(AppKeys.Application.appName)|\(AppKeys.Application.osName)|\(String.randomString(length: 10))"
                Self.appInstallIdentifier = newIdentifier
                return newIdentifier
            }
            
            // Write to memory if needed so we are not hitting the disk every-time.
            if Self._appInstallIdentifier == nil {
                Self._appInstallIdentifier = identifier
            }
            
            return identifier
        }
        set {
            standard.set(newValue, forKey: AppKeys.Application.appInstallIdentifierKey)
            Self._appInstallIdentifier = newValue
        }
    }
    
    /// Returns unique list of channels marked as favorites.
    static var favorites: [GuideChannel] {
        get {
            let data = standard.data(forKey: AppKeys.GuideStore.favoritesKey)
            let _favorites = try? [GuideChannel].initialize(jsonData: data)
            return _favorites ?? []
        }
        set {
            let uniqueFavs = Array(Set(newValue))
            let data = try? uniqueFavs.toJSONData()
            standard.set(data, forKey: AppKeys.GuideStore.favoritesKey)
        }
    }
    
    /// Returns the last played channel.
    static var lastPlayed: GuideChannel? {
        get {
            let data = standard.data(forKey: AppKeys.GuideStore.lastPlayedKey)
            let _lastPlayed = try? GuideChannel.initialize(jsonData: data)
            return _lastPlayed
        }
        set {
            let data = try? newValue?.toJSONData()
            standard.set(data, forKey: AppKeys.GuideStore.lastPlayedKey)
        }
    }
}
