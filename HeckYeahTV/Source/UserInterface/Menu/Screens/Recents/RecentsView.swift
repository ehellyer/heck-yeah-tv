//
//  RecentsView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct RecentsView: View {

    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @Query(sort: \RecentlyViewedChannel.viewedAt, order: .reverse)
    private var recentlyViewed: [RecentlyViewedChannel]
    @Namespace private var focusNamespace
    @FocusState private var focusedChannelId: String?
    
    private var recentChannelIds: [ChannelId] {
        // Get top 10 channel IDs from recently viewed
        recentlyViewed.prefix(10).compactMap { $0.channel.id }
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        ForEach(recentChannelIds, id: \.self) { channelId in
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
                    if let firstChannelId = recentChannelIds.first {
                        focusedChannelId = firstChannelId
                        DispatchQueue.main.asyncAfter(deadline: .now() + settleTime) {
                            proxy.scrollTo(recentChannelIds.first ?? "")
                        }
                    }
                }
            }

            
            if recentChannelIds.isEmpty {
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
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    @Previewable @State var navigationPath: [SettingsDestination] = []
    
    // Override the injected AppStateProvider
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[0]
    appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[2]
    appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[5]
    appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[6]
    appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[7]
    
    
    return TVPreviewView {
        RecentsView()
            .modelContainer(swiftDataController.container)
    }
}
