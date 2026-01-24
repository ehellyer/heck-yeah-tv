//
//  ListButtonStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/24/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ListButtonStyle: ButtonStyle {
    
    @State var isSelected: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isFocused) private var isFocused: Bool
    
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: AppStyle.cornerRadius)
            .fill(backgroundFill)
    }
    
    private var backgroundFill: Color {
        if isFocused {
            return Color.guideBackgroundFocused
        } else if isSelected {
            return Color.guideSelectedChannelBackground
        }
        return Color.guideBackgroundNoFocus
    }
    
    private func scale(isPressed: Bool) -> CGFloat {
        if isFocused {
            return 1.02
        }
        return isPressed ? 0.98 : 1.0
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(rowBackground)
            .scaleEffect(scale(isPressed: configuration.isPressed))
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
