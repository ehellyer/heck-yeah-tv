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
    @State var hideGuideInfo: Bool
    @Environment(\.modelContext) private var viewContext
    @StateObject private var loader = GuideRowLoader()
    
    var body: some View {
        Group {
            if let channel = loader.channel {
                GuideRow(channel: channel,
                         appState: $appState,
                         hideGuideInfo: hideGuideInfo)
            } else {
                GuideRow(channel: nil,
                         appState: $appState,
                         hideGuideInfo: hideGuideInfo)
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

    // Override the injected SwiftDataController
    let mockData = MockDataPersistence()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.guideChannelMap.map[6]

    return TVPreviewView() {
        GuideRowLazy(channelId: channelId,
                     appState: $appState,
                     hideGuideInfo: true)
            .modelContext(mockData.context)
            //.redacted(reason: .placeholder)
    }
}
