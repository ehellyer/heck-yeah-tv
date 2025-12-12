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
    let mockData = MockDataPersistence(appState: appState)
    
    let swiftController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftController
    
    let channelId = swiftController.guideChannelMap.map[6]

    return GuideRowLazy(channelId: channelId,
                        appState: $appState,
                        hideGuideInfo: true)
        .environment(\.modelContext, mockData.context)
}
