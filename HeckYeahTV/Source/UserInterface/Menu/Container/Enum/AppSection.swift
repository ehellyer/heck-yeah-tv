//
//  AppSection.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Hellfire

enum AppSection: String, CaseIterable, Identifiable, JSONSerializable {
    
    /// Allows screen for Play/Pause on iOS and macOS devices.
    case playerControls
    
    /// Last recently viewed channels (probably max of 10)
    case recents
    
    /// All channels (with on screen toggle to show favorites only)
    case guide

    /// Settings and things
    case settings
}

extension AppSection {
    
    /// Identifiable id
    var id: String { rawValue }
    
    /// Tab name title string
    var title: String {
        switch self {
            case .playerControls: return "Player"
            case .recents: return "Recents"
            case .guide: return "Guide"
            case .settings: return "Settings"
        }
    }
    
    /// Tab name icon.
    var systemImage: String {
        switch self {
            case .playerControls: return "play.fill"
            case .recents: return "clock.fill"
            case .guide: return "list.bullet.rectangle.fill"
            case .settings: return "gearshape.fill"
        }
    }
}
