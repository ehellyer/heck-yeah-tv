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

    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @Query private var recentlyViewed: [RecentlyViewedChannel]
    @Namespace private var focusNamespace
    @FocusState private var focusedChannelId: String?
    
    init() {
        let descriptor = swiftDataController.recentlyViewDescriptor(limit: 10)
        _recentlyViewed = Query(descriptor)
    }
    
    private var recentChannelIds: [ChannelId] {
        // Get top 10 channel IDs from recently viewed
        recentlyViewed.prefix(10).compactMap { $0.channel.id }
    }
    
    private func scrollToTopOfRecents(using proxy: ScrollViewProxy) {
        if let firstChannelId = recentChannelIds.first {
            focusedChannelId = firstChannelId
            DispatchQueue.main.asyncAfter(deadline: .now() + settleTime) {
                proxy.scrollTo(firstChannelId)
            }
        }
    }
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: AppStyle.GuideView.rowSpacing) {
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
                .trackScreen("Recents")
                .onAppear() {
                    scrollToTopOfRecents(using: proxy)
                }
                .onChange(of: recentChannelIds) { _, _ in
                    scrollToTopOfRecents(using: proxy)
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
    
    let channel0 = swiftDataController.channel(for:  swiftDataController.channelBundleMap.channelIds[0])
    let channel1 = swiftDataController.channel(for:  swiftDataController.channelBundleMap.channelIds[1])
    let channel2 = swiftDataController.channel(for:  swiftDataController.channelBundleMap.channelIds[2])
    let channel3 = swiftDataController.channel(for:  swiftDataController.channelBundleMap.channelIds[3])
    let channel4 = swiftDataController.channel(for:  swiftDataController.channelBundleMap.channelIds[4])
    
    swiftDataController.selectedChannel = channel0
    swiftDataController.selectedChannel = channel1
    swiftDataController.selectedChannel = channel2
    swiftDataController.selectedChannel = channel3
    swiftDataController.selectedChannel = channel4
    
    return TVPreviewView {
        RecentsView()
            .modelContainer(swiftDataController.container)
    }
}
