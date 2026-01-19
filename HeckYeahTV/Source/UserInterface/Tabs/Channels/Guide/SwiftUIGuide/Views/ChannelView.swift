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
    @State var isCompact: Bool
    @State var channel: Channel?
    
    @StateObject private var loader = ChannelRowLoader()
    @State private var logoImage: Image = Image(systemName: "tv.circle.fill")
    
    @Injected(\.attachmentController)
    private var attachmentController: AttachmentController

    @State private var swiftDataController: SwiftDataControllable = InjectedValues[\.swiftDataController]
    
    // Focus tracking for each button
    @FocusState private var focusedButton: FocusedButton?

    private var isFavoriteChannel: Bool {
        return channel?.favorite?.isFavorite ?? false
    }
    
    private var isPlaying: Bool {
        guard let selectedChannelId = appState.selectedChannel else {
            return false
        }
        return selectedChannelId == channel?.id
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



#Preview("ChannelView - loads from Mock SwiftData") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()

    let isCompact: Bool = true
    
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
                        isCompact: isCompact,
                        channel: channel1)
            
            ChannelView(appState: $appState,
                        isCompact: isCompact,
                        channel: channel2)
            
            ChannelView(appState: $appState,
                        isCompact: isCompact,
                        channel: channel3)
            
        }
        .onAppear {
            appState.selectedChannel = swiftDataController.channelBundleMap.map[9]
        }
    }
}
