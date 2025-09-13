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
    @Environment(GuideStore.self) var guideStore
    @FocusState.Binding var focus: FocusTarget?
    
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
                        
                    GuideSubTitleView(channel: channel)
                }
                .frame(width: 400, alignment: .leading)
            }
            .focused($focus, equals: FocusTarget.guide(channelId: channel.id, col: 0))
            
            Spacer()
            
            Button {
                guideStore.toggleFavorite(channel)
            } label: {
                Image(systemName: guideStore.isFavorite(channel) ? "star.fill" : "star")
                    .foregroundStyle(Color.yellow)
            }
            .focused($focus, equals: FocusTarget.guide(channelId: channel.id, col: 1))
            
        }
        .padding(.vertical, rowVPad)
        .padding(.horizontal, rowHPad)
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
    }
}
