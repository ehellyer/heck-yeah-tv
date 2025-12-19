//
//  ListButtonStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/24/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ListButtonRow: View {
    
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                
                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
//                if isSelected {
//                    Image(systemName: "checkmark.circle.fill")
//                        .font(.body.weight(.bold))
//                        .foregroundStyle(textColor)
//                        .symbolRenderingMode(.hierarchical)
//                }
            }
            .padding(.vertical, rowVerticalPadding)
            .padding(.horizontal, rowHorizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(ListButton(isSelected: isSelected))
        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
#if !os(tvOS)
        .listRowSeparator(.hidden)
#endif
        .listRowBackground(Color.clear)
        //.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var textColor: Color {
        if isSelected {
            return colorScheme == .dark ? .white : .primary
        } else {
            return .primary.opacity(0.75)
        }
    }

    
    private var rowVerticalPadding: CGFloat {
#if os(tvOS)
        return 20
#else
        return 12
#endif
    }
    
    private var rowHorizontalPadding: CGFloat {
#if os(tvOS)
        return 24
#else
        return 16
#endif
    }
}

//MARK: - ListButton
private struct ListButton: ButtonStyle {
    
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
