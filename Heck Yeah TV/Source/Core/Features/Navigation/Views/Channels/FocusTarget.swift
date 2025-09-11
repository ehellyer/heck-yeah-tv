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
    case guide(row: Int, col: Int)
}

extension FocusTarget: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
            case .favoritesToggle:
                return "FavoritesToggle"
            case .guide(row: let row, col: let col):
                return "Guide(row:\(row), col:\(col))"
        }
    }
}
