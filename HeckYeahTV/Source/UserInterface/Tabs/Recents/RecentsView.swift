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
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 15) {
                    ForEach(appState.recentChannelIds, id: \.self) { channelId in
                        GuideRowLazy(channelId: channelId,
                                     appState: $appState,
                                     hideGuideInfo: true)
                        .id(channelId)
                    }
                    if appState.recentChannelIds.isEmpty {
                        Text("No recent channels.")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .focusable(false)
                    }
                }
            }
            .background(.clear)
            .scrollClipDisabled(true)
            .contentMargins(.top, 5)
            .contentMargins(.bottom, 5)
        }
    }
}

#Preview("RecentsView") {
    @Previewable @State var appState: AppStateProvider = SharedAppState.shared
    let mockData = MockDataPersistence(appState: appState)

    let swiftController = MockSwiftDataController(viewContext: mockData.context,
                                                  selectedCountry: "US",
                                                  selectedCategory: nil,//"news",
                                                  showFavoritesOnly: false,
                                                  searchTerm: nil)//"Lo")
    InjectedValues[\.swiftDataController] = swiftController

    appState.selectedChannel = swiftController.guideChannelMap.map[0]
    appState.selectedChannel = swiftController.guideChannelMap.map[1]
    appState.selectedChannel = swiftController.guideChannelMap.map[2]
    appState.selectedChannel = swiftController.guideChannelMap.map[3]
    appState.selectedChannel = swiftController.guideChannelMap.map[4]
    appState.selectedChannel = swiftController.guideChannelMap.map[5]
    appState.selectedChannel = swiftController.guideChannelMap.map[6]
    appState.selectedChannel = swiftController.guideChannelMap.map[7]
    appState.selectedChannel = swiftController.guideChannelMap.map[8]
    appState.selectedChannel = swiftController.guideChannelMap.map[9]
    appState.selectedChannel = swiftController.guideChannelMap.map[10]
    appState.selectedChannel = swiftController.guideChannelMap.map[11]
    appState.selectedChannel = swiftController.guideChannelMap.map[12]
    
    return RecentsView(appState: $appState)
        .environment(\.modelContext, mockData.context)
}
