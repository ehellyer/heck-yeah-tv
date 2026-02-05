//
//  NoChannelProgramView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/4/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NoChannelProgramView: View {
    
    @State var channelId: ChannelId
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @FocusState private var focusedButton: FocusedButton?
    
    private var isPlaying: Bool {
        return appState.selectedChannel == channelId
    }
    
    var body: some View {
        Button {
            // No op
        } label: {
            Text("No guide information")
                .font(AppStyle.Fonts.programViewFont)
                .padding(.horizontal, AppStyle.ProgramView.internalHorizontalPadding)
                .frame(height: AppStyle.ProgramView.height)
                .frame(maxWidth: .infinity)
        }
        .disabled(true)
        .focusable(false)
        .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                          cornerRadius: AppStyle.cornerRadius,
                                          isFocused: focusedButton == .guide,
                                          isProgramNow: false))
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.channelBundleMap.channelIds[1]
    //appState.selectedChannel = channelId
    
    return TVPreviewView() {
        NoChannelProgramView(channelId: channelId)
    }
}
