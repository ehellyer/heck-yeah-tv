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
    @Environment(\.modelContext) private var viewContext
    @Namespace private var focusNamespace
    @FocusState private var focusedChannelId: String?
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        ForEach(appState.recentChannelIds, id: \.self) { channelId in
                            ChannelViewLoader(channelId: channelId)
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
                    Text("Go to the guide to find and select channels")
                        .font(.subheadline)
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
            .environment(\.modelContext, swiftDataController.viewContext)
            .onAppear() {
                // Load some recent channels
                appState.selectedChannel = swiftDataController.channelBundleMap.map[0].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[1].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[2].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[3].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[4].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[5].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[6].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[7].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[9].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[10].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[11].channelId
                appState.selectedChannel = swiftDataController.channelBundleMap.map[8].channelId
            }
    }
}
