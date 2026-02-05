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

    @State var channel: Channel?

    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @FocusState private var focusedButton: FocusedButton?
    
    private var isPlaying: Bool {
        let selectedChannelId = appState.selectedChannel
        return selectedChannelId != nil && selectedChannelId == channel?.id
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: AppStyle.ChannelView.favButtonTrailing) {
            
            FavoriteView(channelId: channel?.id)
            
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
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channel1 = try! swiftDataController.channel(for: swiftDataController.channelBundleMap.channelIds[1])
    let channel2 = try! swiftDataController.channel(for: swiftDataController.channelBundleMap.channelIds[14])
    let channel3 = try! swiftDataController.channel(for: swiftDataController.channelBundleMap.channelIds[9])
    
    return TVPreviewView() {
        VStack {

            ChannelView(channel: channel1)
            
            ChannelView(channel: channel2)
            
            ChannelView(channel: channel3)
            
        }
        .onAppear {
            appState.selectedChannel = swiftDataController.channelBundleMap.channelIds[9]
        }
    }
}
