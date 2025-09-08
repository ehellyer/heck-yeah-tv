//
//  GuideRow.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideRow: View {
    let rowVPad: CGFloat = 6
    let rowHPad: CGFloat = 15
    let corner: CGFloat = 14
    
    @State var channel: GuideChannel
    @State var row: Int
    @Environment(GuideStore.self) var guideStore
    @FocusState.Binding var focus: FocusTarget?
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
                        .frame(width: 300, alignment: .leading)
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
            .tint(guideStore.isFavorite(channel) ? Color.yellow : Color.white)            
        }
        .padding(.vertical, rowVPad)
        .padding(.leading, rowHPad)
        .padding(.trailing, rowHPad)
        .background {
            Color.clear
            if guideStore.selectedChannel == channel {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.mainAppGreen.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(Color.mainAppGreen.opacity(0.22), lineWidth: 1)
                    )
            }
        }
        
        .tag(row)
        .id(row)
    }
}
