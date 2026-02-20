//
//  TVNavigationLink.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/10/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

/// Custom navigation link to override the very opinionated built in styling.
struct TVNavigationLink<Label: View, Destination: View>: View {
    
    let label: Label
    let destination: Destination
    
    init(@ViewBuilder label: () -> Label, @ViewBuilder destination: () -> Destination) {
        self.label = label()
        self.destination = destination()
    }
    
    var body: some View {
        Group {
            ZStack(alignment: .leading) {
                NavigationLink(destination: destination) {
                    EmptyView()
                }
                .opacity(0)
                
                HStack {
                    label
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(white: 0.4))
                        .font(.system(size: 14, weight: .semibold))
                }
            }
        }
    }
}

struct FocusableModifier: ViewModifier {

    @Environment(\.isFocused) private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .background(isFocused ? .red : .blue)
            .scaleEffect(isFocused ? 1.1 : 1.0)
            .shadow(color: isFocused ? Color.black.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .focusable()
    }
}

extension View {
    func customFocusableEffect() -> some View {
        self.modifier(FocusableModifier())
    }
}
