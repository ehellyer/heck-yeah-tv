//
//  FocusableButtonStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct FocusableButtonStyle: ButtonStyle {
    let isPlaying: Bool
    let cornerRadius: CGFloat
    let isFocused: Bool
    private let focusGrowth: CGFloat = 15 // Fixed pixel growth
    
    @State private var buttonSize: CGSize = .zero
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundColor)  // Move this BEFORE other modifiers
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            buttonSize = geometry.size
                        }
                        .onChange(of: geometry.size) { oldValue, newValue in
                            buttonSize = newValue
                        }
                }
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
            )
            .scaleEffect(scaleAmount(for: buttonSize))
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
    
    private func scaleAmount(for size: CGSize) -> CGFloat {
        guard isFocused else { return 1.0 }
        let minDimension = max(size.width, 1.0)
        let scaleFactor = (minDimension + focusGrowth) / minDimension
        return scaleFactor
    }
    
    private var foregroundColor: Color {
        if isFocused {
            return .guideForegroundFocused
        } else {
            return .guideForegroundNoFocus
        }
    }
    
    private var backgroundColor: Color {
        if isFocused {
            return .guideBackgroundFocused
        } else {
            return isPlaying ? .guideSelectedChannelBackground : .guideBackgroundNoFocus
        }
    }
}
