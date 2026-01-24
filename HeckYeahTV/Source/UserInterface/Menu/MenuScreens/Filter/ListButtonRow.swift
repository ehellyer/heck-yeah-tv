//
//  ListButtonRow.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/28/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ListButtonRow: View {
    
    let emoji: String?
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let emoji {
                    Text(emoji)
                        .font(.body)
                        .fontWeight(isSelected ? .bold : .regular)
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Text(title)
                    .font(.body)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
            .padding(.vertical, rowVerticalPadding)
            .padding(.horizontal, rowHorizontalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(ListButtonStyle(isSelected: isSelected))
        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
#if !os(tvOS)
        .listRowSeparator(.hidden)
#endif
        .listRowBackground(Color.clear)
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
