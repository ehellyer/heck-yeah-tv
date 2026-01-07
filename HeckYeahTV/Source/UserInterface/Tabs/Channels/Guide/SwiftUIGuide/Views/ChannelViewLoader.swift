//
//  ChannelViewLoader.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/14/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct ChannelViewLoader: View {
    
    @Binding var appState: AppStateProvider
    let channelId: ChannelId
    @State var isCompact: Bool
    
    @Environment(\.modelContext) private var viewContext
    @StateObject private var loader = ChannelRowLoader()
    
    var body: some View {
        let channel = loader.channel
        ChannelView(appState: $appState,
                    isCompact: isCompact,
                    channel: channel)
        .modifier(RedactedIfNeeded(type: channel))
        .onAppear {
            loader.load(channelId: channelId, context: viewContext)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

#Preview("ChannelViewLoader") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    let isCompact: Bool = true
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.channelBundleMap.map[41]
    
    return TVPreviewView() {
        ChannelViewLoader(appState: $appState,
                        channelId: channelId,
                        isCompact: isCompact)
        .modelContext(mockData.context)
    }
}
