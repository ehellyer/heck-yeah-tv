//
//  MainAppContentView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct MainAppContentView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var fadeTask: Task<Void, Never>?
    @State private var showPlayToast = false
    @State private var appState: SharedAppState = SharedAppState()
    @Query(filter: #Predicate<IPTVChannel> { $0.isPlaying }, sort: []) private var playingChannels: [IPTVChannel]
    private var selectedChannelId: ChannelId? { playingChannels.first?.id }
    
#if os(tvOS)
    // Ensures we deterministically focus the activation layer when the guide is hidden.
    @FocusState private var activationHasFocus: Bool
#endif
    
    var body: some View {
        // Alignment required to layout the play/pause button in the bottom left corner.
        ZStack(alignment: .bottomLeading)  {
            VLCPlayerView(appState: $appState, selectedChannelId: selectedChannelId)
                .zIndex(0)
                .ignoresSafeArea(.all)
            
            if appState.isPlayerPaused {
                PlaybackBadge(isPlaying: false)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
            }
            
            if appState.isPlayerPaused == false && showPlayToast {
                PlaybackBadge(isPlaying: true)
                    .allowsHitTesting(false)
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
            }
            
            if appState.isGuideVisible {
                TabContainerView(appState: $appState)
                    .zIndex(1)
                    .transition(.opacity)
            } else {
                TabActivationView(appState: $appState)
#if os(tvOS)
                    // Make sure this gets initial focus when visible so select and commands route correctly.
                    .focused($activationHasFocus)
                    .onAppear {
                        activationHasFocus = true
                    }
                    .onChange(of: appState.isGuideVisible) { _, newValue in
                        // When hiding the guide, reclaim focus on the activation layer.
                        if newValue == false {
                            activationHasFocus = true
                        }
                    }
#endif
                    .zIndex(1000)
            }
        }
        
#if os(tvOS)
        .onPlayPauseCommand {
            appState.isPlayerPaused.toggle()
        }
#endif
        
        .onChange(of: appState.isPlayerPaused, { _, newValue in
            fadeTask?.cancel()
            fadeTask = nil
            
            if newValue == true {
                showPlayToast = false
            } else {
                fadeTask = Task { @MainActor in
                    showPlayToast = true
                    do {
                        try await Task.sleep(nanoseconds: 2_000_000_000) //2 Seconds
                        try Task.checkCancellation()
                        showPlayToast = false
                    } catch {
                        // Task Cancelled - no op.
                    }
                }
            }
        })
        
        .onChange(of: scenePhase,  { _, _ in
            if scenePhase != .active && appState.isGuideVisible {
                appState.isGuideVisible = false
            }
        })
        
#if os(macOS)
        // macOS: arrow keys re-show the guide
        .background( MacArrowKeyCatcher {
            withAnimation {
                guideStore.isGuideVisible = true
            }
        })
#endif
    }
}
