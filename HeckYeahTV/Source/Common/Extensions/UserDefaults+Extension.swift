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
    
    /// A boolean to indicate if channels should be filtered to show only channels indicated as favorites.  Persisted into UserDefaults.standard.
    static var showFavorites: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.showFavoritesKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.showFavoritesKey)
        }
    }
    
    /// A boolean to indicate to SwiftUI if the Guide TabView should be displayed.
    static var isGuideVisible: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.isGuideVisible)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.isGuideVisible)
        }
    }
    
    /// A boolean to indicate if playback is in a paused state.  This is different from stopped.  Not all streams can be paused..  Persisted into UserDefaults.standard.
    static var isPlayerPaused: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.isPlayerPaused)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.isPlayerPaused)
        }
    }

    /// Gets or sets the last tab that was selected.  Defaults to Channels tab for new installation.  Persisted into UserDefaults.standard.
    static var selectedTab: TabSection {
        get {
            let _data: Data? = standard.data(forKey: AppKeys.SharedAppState.selectedTab)
            let _lastTab: TabSection = (try? TabSection.initialize(jsonData: _data)) ?? TabSection.channels //Channels tab is default for new install
            return _lastTab
        }
        set {
            let data = try? newValue.toJSONData()
            standard.set(data, forKey: AppKeys.SharedAppState.selectedTab)
        }
    }
}
