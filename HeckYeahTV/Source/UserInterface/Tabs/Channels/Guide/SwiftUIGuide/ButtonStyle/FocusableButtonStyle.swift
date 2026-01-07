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
    let isProgramNow: Bool
    
    @State private var buttonSize: CGSize = .zero
    
    func makeBody(configuration: Configuration) -> some View {
        
        let foregroundColor: Color = AppStyle.GuideView.foregroundColor(isFocused: isFocused)
        let backgroundColor: Color = AppStyle.GuideView.backgroundColor(isFocused: isFocused, isPlaying: isPlaying, isProgramNow: isProgramNow)

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
            .scaleEffect(AppStyle.GuideView.scaleAmount(for: buttonSize, isFocused: isFocused))
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
