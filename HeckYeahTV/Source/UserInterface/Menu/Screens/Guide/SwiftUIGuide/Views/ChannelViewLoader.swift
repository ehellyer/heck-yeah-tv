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
    
    let channelId: ChannelId
    @State var hideFavoritesView: Bool = false
    
    @StateObject private var loader = ChannelRowLoader()
    
    var body: some View {
        let channel = loader.channel
        ChannelView(channel: channel,
                    hideFavoritesView: hideFavoritesView)
            .modifier(RedactedIfNeeded(type: channel))
            .onAppear {
                loader.load(channelId: channelId)
            }
            .onDisappear {
                loader.cancel()
            }
    }
}

#Preview("ChannelViewLoader") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.channelBundleMap.channelIds[2]
    
    return TVPreviewView() {
        ChannelViewLoader(channelId: channelId)
    }
}
