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
    @State private var showPlayButtonToast = false
    @State private var appState: SharedAppState = SharedAppState.shared

    @State private var lastFocusedChannel: ChannelId?
    @FocusState var focus: FocusTarget?
    
    // IPTVChannelMap
    @Query(filter: #Predicate<IPTVChannelMap> { $0.id == channelMapKey }, sort: []) private var channelMaps: [IPTVChannelMap]
    private var channelMap: IPTVChannelMap { return channelMaps.first! }
    
    
    var body: some View {
        // Alignment required to layout the play/pause button in the bottom left corner.
        ZStack(alignment: .bottomLeading)  {
            
            //VLCPlayerView(appState: $appState)
            VideoPlayerView(appState: $appState)
                .zIndex(0)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .focusable(false)
                
            if appState.isGuideVisible {
                TabContainerView(focus: $focus, appState: $appState, channelMap: channelMap)
                    .transition(.opacity)
                    .background(Color.black.opacity(0.65))  //Apply a shady shim behind the whole view so that TV can be seen behind, but the UI is visible.
            } else {
                TabActivationView(appState: $appState)
                    // If TabActivationView is being rendered then we want it on top of everything.
                    .zIndex(1000)
#if os(tvOS)
                    // Make sure this gets initial focus when visible so select and commands route correctly.
                    .focused($focus, equals: .guideActivationView)
                    .defaultFocus($focus, .guideActivationView)
                    .onAppear() {
                        focus = .guideActivationView
                    }
                    
#endif
            }
            
            if appState.isPlayerPaused {
                PlaybackBadge(isPlaying: false)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
            }
            
            if appState.isPlayerPaused == false && showPlayButtonToast {
                PlaybackBadge(isPlaying: true)
                    .allowsHitTesting(false)
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
            }
            
            // Global debug overlay (always on top)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Focus: \(focus?.debugDescription ?? "nil") || Tab: \(appState.selectedTab.title) || isPaused: \(appState.isPlayerPaused ? "Yes" : "No") || isGuideShowing: \(appState.isGuideVisible ? "Yes" : "No") || ShowFavorites: \(appState.showFavoritesOnly ? "Yes" : "No")")
                        .padding(10)
                        .fontWeight(.bold)
                        .background(Color(.gray))
                        .focusable(false)
                        .allowsHitTesting(false) 
                }
                .padding()
            }
            .zIndex(10000)
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
                showPlayButtonToast = false
            } else {
                fadeTask = Task { @MainActor in
                    showPlayButtonToast = true
                    do {
                        try await Task.sleep(nanoseconds: 2_000_000_000) //2 Seconds
                        try Task.checkCancellation()
                        showPlayButtonToast = false
                    } catch {
                        // Task Cancelled - no op.
                    }
                }
            }
        })
        
        .onChange(of: scenePhase,  { _, newValue in
            // If app becomes not-active with the guide up, dismiss the guide.
            if newValue != .active && appState.isGuideVisible {
                appState.isGuideVisible = false
            }
        })
        
        .onChange(of: focus) { oldValue, newValue in
            if case .guide(let channelId, let col) = focus, 0...1 ~= col {
                lastFocusedChannel = channelId
            }
            logConsole("onChange(of: focus) observed: old = \(oldValue?.debugDescription ?? "nil") new = \(newValue?.debugDescription ?? "nil")")
        }

#if os(macOS)
        // macOS: arrow keys re-show the guide
        .background( MacArrowKeyCatcher {
            withAnimation {
                appState.isGuideVisible = true
            }
        })
#endif
    }
}

