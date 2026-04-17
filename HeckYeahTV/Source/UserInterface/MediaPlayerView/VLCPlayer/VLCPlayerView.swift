//
//  VLCPlayerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

@MainActor
struct VLCPlayerView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var isStreamUnplayable = false
    @State private var isSwitchingStreams = false
    
    private var selectedChannel: Channel? { swiftDataController.selectedChannel }
    
    var body: some View {
        ZStack {
            VLCPlayerRepresentable(
                selectedChannel: selectedChannel,
                shouldPause: appState.isPlayerPaused,
                scenePhase: scenePhase,
                playerVolume: appState.playerVolume,
                isStreamUnplayable: $isStreamUnplayable,
                isSwitchingStreams: $isSwitchingStreams,
                appState: appState
            )
            .opacity(isStreamUnplayable ? 0 : 1)
            
            if isStreamUnplayable {
                UnplayableStreamOverlay()
            }
            
            if isSwitchingStreams {
                StreamSwitchingActivity()
            }
        }
        .trackScreen("Player")
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Resets flags when resuming from BG.
            if newPhase == .active {
                isStreamUnplayable = false
                isSwitchingStreams = false
            }
        }
    }
}
