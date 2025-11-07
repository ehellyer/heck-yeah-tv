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
    @Binding var appState: AppStateProvider
    @Environment(\.modelContext) private var viewContext
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    private var isPlaying: Bool {
        appState.selectedChannel == channel.id
    }
    
    var body: some View {
        HStack(spacing: 10) {

            Button {
                channel.isFavorite.toggle()
            } label: {
                Image(systemName: channel.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(Color.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
            }
            
            Button {
                appState.selectedChannel = channel.id
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.title)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        
                    GuideSubTitleView(channel: channel)
                }
                
            }

            if (isLandscape) {
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
            }
            Spacer()
        }
        .background {
            if isPlaying {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color.selectedChannel)
                    .padding(-5) // Extend effect visually beyond the row (bleed out)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

#if !os(tvOS)
#Preview("GuideRow - loads from Mock SwiftData") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState(selectedChannel: "chan.movies.001")
    
    let mockData = MockDataPersistence(appState: appState)
    
    GuideRow(channel: mockData.channels[1],
             appState: $appState)
        .environment(\.modelContext, mockData.context)
}
#endif
