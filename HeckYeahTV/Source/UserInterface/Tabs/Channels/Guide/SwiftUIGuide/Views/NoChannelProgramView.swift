//
//  NoChannelProgramView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/4/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NoChannelProgramView: View {
    
    @Binding var appState: AppStateProvider
    @State var channelId: ChannelId
    
    @FocusState private var focusedButton: FocusedButton?
    
    private var isPlaying: Bool {
        return appState.selectedChannel == channelId
    }
    
    var body: some View {
        Button {
            // No op
        } label: {
            Text("No guide information")
                .font(AppStyle.Fonts.gridRowFont)
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
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.channelBundleMap.map.first!
    return TVPreviewView() {
        NoChannelProgramView(appState: $appState,
                             channelId: channelId)
    }
}
