//
//  ListButtonStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/24/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ListButtonStyle: ButtonStyle {
    
    @Environment(\.isFocused) var isFocused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                Capsule()
                    .fill(isFocused ? .guideBackgroundFocused : .guideBackgroundNoFocus)
            )
            .foregroundColor(isFocused ? .guideForegroundFocused : .guideForegroundNoFocus)
            .scaleEffect(isFocused ? 1.01 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}
