//
//  FocusTarget.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

enum FocusTarget: Hashable {
    case guideActivationView
    case favoritesToggle
    case tabBar             // New: focus redirection target for the TabView area
    case guide(channelId: String, col: Int)
}

extension FocusTarget: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
            case .guideActivationView:
                return "guideActivationView"
            case .favoritesToggle:
                return "favoritesToggle"
            case .tabBar:
                return "tabBar"
            case .guide(channelId: let channelId, col: let col):
                return "guide(channelId: \(channelId.prefix(8)), col: \(col))"
        }
    }
}

