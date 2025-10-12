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
    let corner: CGFloat = 40
    
    @State var channel: IPTVChannel
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    @Environment(\.modelContext) private var viewContext
    
    var body: some View {
        HStack(spacing: 25) {

            Button {
                channel.isFavorite.toggle()
            } label: {
                Image(systemName: channel.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(Color.yellow)
                    .padding(.horizontal, 0)
                    .padding(.vertical, 40)
                    .scaleEffect(1.5)
            }
            .focused($focus, equals: FocusTarget.guide(channelId: channel.id, col: 0))
            
            Button {
                setPlayingChannel(id: channel.id)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        
                    GuideSubTitleView(channel: channel)
                }
                .frame(width: 320, alignment: .leading)
                .padding(20)
            }
            .focused($focus, equals: FocusTarget.guide(channelId: channel.id, col: 1))
            
            Button {
                // No op
            } label: {
                Text("No guide information")
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .focusable(false)
        }
        .background {
            if channel.isPlaying {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.selectedChannel)
                    .padding(-15)
            }
        }
    }
    
    private func setPlayingChannel(id: String) {
        do {
            /// There can only be one channel at a time playing, this code enforces that demand.
            let isPlayingPredicate = #Predicate<IPTVChannel> { $0.isPlaying }
            let isPlayingDescriptor = FetchDescriptor<IPTVChannel>(predicate: isPlayingPredicate)
            let channels = try viewContext.fetch(isPlayingDescriptor)
            
            let targetChannelPredicate = #Predicate<IPTVChannel> { $0.id == id }
            var targetChannelDescriptor = FetchDescriptor<IPTVChannel>(predicate: targetChannelPredicate)
            targetChannelDescriptor.fetchLimit = 1
            let targetChannel = try viewContext.fetch(targetChannelDescriptor).first
            
            for channel in channels {
                channel.isPlaying = false
            }
            targetChannel?.isPlaying = true
            
            try viewContext.save()
        } catch {
            print("Error: \(error) when setting a channel as playing")
        }
    }
}
