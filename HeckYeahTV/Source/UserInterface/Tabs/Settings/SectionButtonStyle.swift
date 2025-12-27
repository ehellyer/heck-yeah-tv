//
//  SectionButtonStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/25/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct SectionButtonStyle: ButtonStyle {
    
    @Environment(\.isFocused) var isFocused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
#if os(tvOS)
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
#else
        configuration.label
#endif

    }
}
