//
//  SettingsRowStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/4/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

// MARK: - Settings Row Modifier

/// Applies consistent styling to settings list rows with glass effects and proper focus behavior on tvOS.
struct SettingsRowModifier: ViewModifier {
    @Environment(\.isFocused) private var isFocused
    
    func body(content: Content) -> some View {
        content
            .listRowBackground(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
#if os(tvOS)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.white.opacity(isFocused ? 0.3 : 0.1), lineWidth: 1)
                    )
#else
                    .background(Color(white: 0.1).opacity(0.8))
#endif
            )
#if !os(tvOS)
            .listRowSeparatorTint(Color(white: 0.6).opacity(0.3))
#endif
    }
}

extension View {
    /// Applies settings row styling with glass effects and proper focus behavior.
    func settingsRowStyle() -> some View {
        modifier(SettingsRowModifier())
    }
}

// MARK: - Settings Button Style

/// Button style for settings actions that provides proper focus effects on tvOS.
struct SettingsButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var isFocused
    var color: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(color)
#if os(tvOS)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
#endif
    }
}

extension ButtonStyle where Self == SettingsButtonStyle {
    /// Button style for settings with proper focus effects.
    static func settings(color: Color = .blue) -> SettingsButtonStyle {
        SettingsButtonStyle(color: color)
    }
}
