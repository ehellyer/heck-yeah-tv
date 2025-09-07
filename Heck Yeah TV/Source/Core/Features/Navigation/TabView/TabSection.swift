//
//  TabSection.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Hellfire

enum TabSection: String, CaseIterable, Identifiable, JSONSerializable {
    
    /// Last Channel
    case last
    
    /// Recently viewed
    case recents
    
    /// All channels (with on screen toggle for favorites only)
    case channels
    
    /// Search channels by name, category, country.
    case search
    
    /// Settings and things
    case settings
}

extension TabSection {
    
    /// Identifiable id
    var id: String { rawValue }
    
    /// Tab name title string
    var title: String {
        switch self {
            case .last: return "Last"
            case .recents: return "Recents"
            case .channels: return "Channels"
            case .search: return "Search"
            case .settings: return "Settings"
        }
    }
    
    /// Tab name icon.
    var systemImage: String {
        switch self {
            case .last: return "arrow.uturn.left.circle.fill"
            case .recents: return "clock.fill"
            case .channels: return "list.bullet.rectangle.fill"
            case .search: return "magnifyingglass"
            case .settings: return "gearshape.fill"
        }
    }
}
