//
//  File.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/9/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

extension Color {
    
    /// Used for debug and previews.
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}
