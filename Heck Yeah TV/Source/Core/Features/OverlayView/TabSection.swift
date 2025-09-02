//
//  TabSection.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

enum TabSection: String, CaseIterable, Identifiable {
    case last
    case recents
    case channels
    case search
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
            case .last: return "Last"
            case .recents: return "Recents"
            case .channels: return "Channels"
            case .search: return "Search"
            case .settings: return "Settings"
        }
    }
    
    var systemImage: String {
        switch self {
            case .last: return "arrow.uturn.left.circle.fill"   // "Last Channel"
            case .recents: return "clock.fill"                 // "Recently viewed"
            case .channels: return "list.bullet.rectangle.fill"// "All channels"
            case .search: return "magnifyingglass"             // "Search"
            case .settings: return "gearshape.fill"            // "Settings"
        }
    }
}
