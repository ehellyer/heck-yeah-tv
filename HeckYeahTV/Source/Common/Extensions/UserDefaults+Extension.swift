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
    static var showFavoritesOnly: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.showFavoritesOnlyKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.showFavoritesOnlyKey)
        }
    }
    
    /// A boolean to indicate to SwiftUI if the Guide TabView should be displayed.
    static var isGuideVisible: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.isGuideVisibleKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.isGuideVisibleKey)
        }
    }
    
    /// A boolean to indicate if playback is in a paused state.  This is different from stopped.  Not all streams can be paused..  Persisted into UserDefaults.standard.
    static var isPlayerPaused: Bool {
        get {
            standard.bool(forKey: AppKeys.SharedAppState.isPlayerPausedKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.isPlayerPausedKey)
        }
    }

    /// Gets or sets the last tab that was selected.  Defaults to Channels tab for new installation.  Persisted into UserDefaults.standard.
    static var selectedTab: TabSection {
        get {
            let _data: Data? = standard.data(forKey: AppKeys.SharedAppState.selectedTabKey)
            let _lastTab: TabSection = (try? TabSection.initialize(jsonData: _data)) ?? TabSection.channels //Channels tab is default for new install
            return _lastTab
        }
        set {
            let data = try? newValue.toJSONData()
            standard.set(data, forKey: AppKeys.SharedAppState.selectedTabKey)
        }
    }

    /// Gets or sets the ChannelId of the currently playing channel.
    static var selectedChannel: ChannelId? {
        get {
            let _channelId: String? = standard.string(forKey: AppKeys.SharedAppState.selectedChannelKey)
            return _channelId
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.selectedChannelKey)
        }
    }
    
    // New: pure-Swift HLS proxy settings
    static var useHLSProxy: Bool {
        get {
            if standard.object(forKey: AppKeys.SharedAppState.useHLSProxyKey) == nil {
                // Default to true across platforms for ease of testing
                return true
            }
            return standard.bool(forKey: AppKeys.SharedAppState.useHLSProxyKey)
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.useHLSProxyKey)
        }
    }
    
    static var hlsProxyPort: Int {
        get {
            let v = standard.integer(forKey: AppKeys.SharedAppState.hlsProxyPortKey)
            return v == 0 ? 8089 : v
        }
        set {
            standard.set(newValue, forKey: AppKeys.SharedAppState.hlsProxyPortKey)
        }
    }
}

