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
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(appState.recentChannelIds, id: \.self) { channelId in
                        GuideRowLazy(channelId: channelId,
                                     appState: $appState,
                                     hideGuideInfo: true)
                        .id(channelId)
                        .padding(.leading, 5)
                        .padding(.trailing, 5)
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
//    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
//    let mockData = MockDataPersistence(appState: appState)
//    appState.selectedChannel = mockData.channels[0].id
//    appState.selectedChannel = mockData.channels[1].id
//    appState.selectedChannel = mockData.channels[2].id
//    appState.selectedChannel = mockData.channels[3].id
//    appState.selectedChannel = mockData.channels[4].id
//
//    return RecentsView(appState: $appState)
//        .environment(\.modelContext, mockData.context)
//        .environment(mockData.channelMap)
}
