//
//  FocusTarget.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

enum FocusTarget: Hashable {
    case favoritesToggle
    case guide(channelId: String, col: Int)
}

extension FocusTarget: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
            case .favoritesToggle:
                return "ShowFavoritesToggle"
            case .guide(channelId: let channelId, col: let col):
                return "Guide(channelId: \(channelId.prefix(8))..., col: \(col))"
        }
    }
}
