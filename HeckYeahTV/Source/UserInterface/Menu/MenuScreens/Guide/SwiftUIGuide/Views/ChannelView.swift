//
//  ChannelView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct ChannelView: View {

    @Binding var appState: AppStateProvider
    @State var channel: Channel?

    @FocusState private var focusedButton: FocusedButton?

    private var isFavoriteChannel: Bool {
        return channel?.favorite?.isFavorite ?? false
    }
    
    private var isPlaying: Bool {
        let selectedChannelId = appState.selectedChannel
        return selectedChannelId != nil && selectedChannelId == channel?.id
    }

    var body: some View {
        HStack(alignment: .center, spacing: 15) {
            
            FavoriteView(appState: $appState,
                         channel: channel)
            
            Button {
                appState.selectedChannel = channel?.id
            } label: {
                ChannelName(channel: channel)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxHeight: .infinity)
            }
            .focused($focusedButton, equals: .channel)
            .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                              cornerRadius: AppStyle.cornerRadius,
                                              isFocused: focusedButton == .channel,
                                              isProgramNow: false))
        }
        .frame(height: AppStyle.ChannelView.height)
        .fixedSize(horizontal: false, vertical: true)
    }
}



#Preview("ChannelView - Favorite toggle and channel selection") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()

    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channel1 = swiftDataController.previewOnly_fetchChannel(at: 7)
    let channel2 = swiftDataController.previewOnly_fetchChannel(at: 41)
    let channel3 = swiftDataController.previewOnly_fetchChannel(at: 9)
    
    return TVPreviewView() {
        VStack {

            ChannelView(appState: $appState,
                        channel: channel1)
            
            ChannelView(appState: $appState,
                        channel: channel2)
            
            ChannelView(appState: $appState,
                        channel: channel3)
            
        }
        .onAppear {
            appState.selectedChannel = swiftDataController.channelBundleMap.map[9]
        }
    }
}
