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
    
    /// Last recently viewed channels (probably max of 10)
    case recents
    
    /// All channels (with on screen toggle for favorites only)
    case channels
    
    /// Settings and things
    case settings
}

extension AppSection {
    
    /// Identifiable id
    var id: String { rawValue }
    
    /// Tab name title string
    var title: String {
        switch self {
            case .recents: return "Recents"
            case .channels: return "Channels"
            case .settings: return "Settings"
        }
    }
    
    /// Tab name icon.
    var systemImage: String {
        switch self {
            case .recents: return "clock.fill"
            case .channels: return "list.bullet.rectangle.fill"
            case .settings: return "gearshape.fill"
        }
    }
}
