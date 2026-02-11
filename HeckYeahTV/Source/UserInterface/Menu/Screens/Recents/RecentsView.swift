//
//  RecentsView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct RecentsView: View {

    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @Namespace private var focusNamespace
    @FocusState private var focusedChannelId: String?
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        ForEach(appState.recentChannelIds, id: \.self) { channelId in
                            ChannelViewLoader(channelId: channelId,
                                              hideFavoritesView: true)
                            .id(channelId)
                        }
                    }
                }
                .scrollClipDisabled(true)
                .background(.clear)
                .contentMargins(.top, 5)
                .contentMargins(.bottom, 5)
                .scrollIndicators(.visible)
                .onAppear() {
                    if let firstChannelId = appState.recentChannelIds.first {
                        focusedChannelId = firstChannelId
                        DispatchQueue.main.asyncAfter(deadline: .now() + settleTime) {
                            proxy.scrollTo(appState.recentChannelIds.first ?? "")
                        }
                    }
                }
            }

            
            if appState.recentChannelIds.isEmpty {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "tv.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.white)
                    Text("No recently selected channels")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .focusable(false)
            }
        }
    }
}

#Preview("RecentsView") {
    // Override the injected AppStateProvider
    var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        RecentsView()
            .onAppear() {
                // Load some recent channels
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[0]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[1]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[2]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[3]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[4]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[5]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[6]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[7]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[9]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[10]
                appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[11]
            }
    }
}
