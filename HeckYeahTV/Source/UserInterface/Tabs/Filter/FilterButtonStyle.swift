//
//  FilterButtonStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct FilterButtonStyle: ButtonStyle {
    
    @Environment(\.isFocused) var isFocused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius)
                    .fill(isFocused ? .guideBackgroundFocused : .guideBackgroundNoFocus)
            )
            .foregroundColor(isFocused ? .guideForegroundFocused : .guideForegroundNoFocus)
            .scaleEffect(isFocused ? 1.01 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}
