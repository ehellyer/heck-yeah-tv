//
//  GuideRowLazy.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/14/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct GuideRowLazy: View {
    let channelId: ChannelId
    @Binding var appState: AppStateProvider
    
    @Environment(\.modelContext) private var viewContext
    @StateObject private var loader = GuideRowLoader()
    
    var body: some View {
        Group {
            if let channel = loader.channel {
                GuideRow(channel: channel,
                         appState: $appState)
            } else {
                HStack(spacing: 25) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .redacted(reason: .placeholder)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 300, height: 18)
                            .redacted(reason: .placeholder)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 220, height: 14)
                            .redacted(reason: .placeholder)
                    }
                    .frame(width: 400, alignment: .leading)
                    .padding(20)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 80)
                        .redacted(reason: .placeholder)
                }
            }
        }
        
        .onAppear {
            loader.load(channelId: channelId, context: viewContext)
        }
        
        .onDisappear {
            loader.cancel()
        }
    }
}

#if !os(tvOS)
#Preview("GuideRowLazy - loads from Mock SwiftData") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState(selectedChannel: "chan.movies.001")
    
    let mockData = MockDataPersistence(appState: appState)
    
    GuideRowLazy(channelId: mockData.channelMap.map[3],
                 appState: $appState)
    .environment(\.modelContext, mockData.context)
    .padding()
}
#endif
