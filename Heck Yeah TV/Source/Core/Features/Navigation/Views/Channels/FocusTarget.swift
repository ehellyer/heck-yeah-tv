//
//  FocusTarget.swift
//  tvOS_HeckYeahTV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

/// Focus targets that can attach to specific views
enum FocusTarget: Hashable {
    case tab(TabSection)
    case favoritesToggle
    case guide(row: Int, col: Int)
}
