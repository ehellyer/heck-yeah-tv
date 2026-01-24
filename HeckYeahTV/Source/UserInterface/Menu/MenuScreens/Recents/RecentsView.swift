//
//  RecentsView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct RecentsView: View {

    @Binding var appState: AppStateProvider
    
    @Environment(\.modelContext) private var viewContext
    @Namespace private var focusNamespace
    @FocusState private var focusedChannelId: String?
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        ForEach(appState.recentChannelIds, id: \.self) { channelId in
                            ChannelViewLoader(appState: $appState,
                                              channelId: channelId)
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
                        .foregroundStyle(.tertiary)
                    Text("No recently selected channels")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Go to the guide to find and select channels")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .focusable(false)
            }
        }
    }
}

#Preview("RecentsView") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()

    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        RecentsView(appState: $appState)
            .environment(\.modelContext, mockData.viewContext)
            .onAppear() {
                // Load some recent channels
                appState.selectedChannel = swiftDataController.channelBundleMap.map[0]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[1]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[2]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[3]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[4]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[5]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[6]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[7]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[9]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[10]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[11]
                appState.selectedChannel = swiftDataController.channelBundleMap.map[8]
            }
    }
}
