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
    
    /// All channels (with on screen toggle to show favorites only)
    case guide

    /// Screen to add favorites by using filters. (select category, use search term, select country, toggle channel as favorite)
    case filter
    
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
            case .guide: return "Guide"
            case .settings: return "Settings"
            case .filter: return "Filter"
        }
    }
    
    /// Tab name icon.
    var systemImage: String {
        switch self {
            case .recents: return "clock.fill"
            case .guide: return "list.bullet.rectangle.fill"
            case .settings: return "gearshape.fill"
            case .filter: return "magnifyingglass"
        }
    }
}
