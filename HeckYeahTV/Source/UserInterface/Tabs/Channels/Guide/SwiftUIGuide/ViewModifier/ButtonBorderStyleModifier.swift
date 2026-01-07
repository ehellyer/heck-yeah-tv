//
//  ButtonBorderStyleModifier.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ButtonBorderStyleModifier: ViewModifier {
    let isBordered: Bool
    let isPlaying: Bool
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        Group {
            if isBordered {
                content.buttonStyle(.bordered)
            } else {
                content.buttonStyle(.borderless)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(isPlaying ? .guideSelectedChannelBackground : .guideBackgroundNoFocus)
                    )
            }
        }
    }
}
