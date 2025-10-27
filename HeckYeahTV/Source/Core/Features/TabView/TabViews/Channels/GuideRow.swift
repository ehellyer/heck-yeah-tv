//
//  GuideRow.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct GuideRow: View {
    let corner: CGFloat = 20
    
    @State var channel: IPTVChannel
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    let isViewVisible: Bool
    @Environment(\.modelContext) private var viewContext
    
    private var isPlaying: Bool {
        appState.selectedChannel == channel.id
    }
    
    var body: some View {
        HStack(spacing: 30) {

            Button {
                channel.isFavorite.toggle()
            } label: {
                Image(systemName: channel.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(Color.yellow)
                    .padding(.horizontal, 0)
                    .padding(.vertical, 40)
                    .scaleEffect(1.5)
            }
            //.buttonStyle(.card)
            .focused($focus, equals: FocusTarget.guide(channelId: channel.id, col: 0))
            .disabled(!isViewVisible)
            
            Button {
                appState.selectedChannel = channel.id
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.title)
                        //.foregroundStyle(Color(((isViewVisible) ? Color.green : Color.red)))  //Debug to help see when partially occluded views are disabled.
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        
                    GuideSubTitleView(channel: channel)
                }
                .frame(width: 320, alignment: .leading)
                .padding(20)
            }
            //.buttonStyle(.card)
            .focused($focus, equals: FocusTarget.guide(channelId: channel.id, col: 1))

            .disabled(!isViewVisible)

            Button {
                // No op
            } label: {
                Text("No guide information")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .disabled(true)
            .focusable(false)
        }
        //.disabled(!isViewVisible)
        .background {
            if isPlaying {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.selectedChannel)
                    .padding(-15) // Extend effect visually beyond the row (bleed out)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}
