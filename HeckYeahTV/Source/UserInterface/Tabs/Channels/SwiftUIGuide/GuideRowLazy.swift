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
                GuideRow(channel: nil,
                         appState: $appState)
                .redacted(reason: .placeholder)
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

#Preview("GuideRowLazy") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    let mockData = MockDataPersistence(appState: appState)
    
    GuideRowLazy(channelId: mockData.channelMap.map[3],
                 appState: $appState)
    .environment(\.modelContext, mockData.context)
}
