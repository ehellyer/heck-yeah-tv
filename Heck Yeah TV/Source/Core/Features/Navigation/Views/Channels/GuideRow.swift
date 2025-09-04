//
//  GuideRow.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideRow: View {
    let rowHPad: CGFloat = 20
    let corner: CGFloat = 14
    
    @State var channel: GuideChannel
    @State var row: Int
    @Environment(GuideStore.self) var guideStore

#if os(tvOS)
    @FocusState.Binding var focus: FocusTarget?
#endif
    @State private var preferredCol: Int = 0
    
    var body: some View {
        HStack {
            Button {
                guideStore.selectedChannel = channel
                guideStore.isPlaying = true
                withAnimation(.easeOut(duration: 0.25)) { guideStore.isGuideVisible = false }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: 420, alignment: .leading)
                    GuideSubTitleView(channel: channel)
                }
            }
#if os(tvOS)
            .focused($focus, equals: FocusTarget.guide(row: row, col: 0))
#endif
            Spacer()
            
            Button {
                guideStore.toggleFavorite(channel)
            } label: {
                Image(systemName: guideStore.isFavorite(channel) ? "star.fill" : "star")
                    .renderingMode(.template)
            }
#if os(tvOS)
            .focused($focus, equals: FocusTarget.guide(row: row, col: 1))
#endif
            .padding(.horizontal, 4)
            
            .tint(guideStore.isFavorite(channel) ? Color.yellow : Color.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, rowHPad)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
