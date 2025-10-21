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
    
    // Focus scopes (Namespace) for isolating focus between guide and activation views
    @Namespace private var guideScope
    @Namespace private var activationScope
    
    // IPTVChannelMap
    @Query(filter: #Predicate<IPTVChannelMap> { $0.id == channelMapKey }, sort: []) private var channelMaps: [IPTVChannelMap]
    private var channelMap: IPTVChannelMap { return channelMaps.first! }
    
    
    var body: some View {
        // Alignment required to layout the play/pause button in the bottom left corner.
        ZStack(alignment: .bottomLeading)  {
            
            VLCPlayerView(appState: $appState)
                .zIndex(0)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .focusable(false)
                
            if appState.isGuideVisible {
                // Scope the entire guide UI to the same FocusState
                TabContainerView(focus: $focus, appState: $appState, channelMap: channelMap)
                    .transition(.opacity)
                    .background(Color.black.opacity(0.65))
#if os(tvOS)
                    .focusScope(guideScope)
#endif
            } else {
                // Scope the activation view separately
                TabActivationView(appState: $appState)
                    // If TabActivationView is being rendered then we want it on top of everything.
                    .zIndex(1000)
#if os(tvOS)
                    .focusScope(activationScope)
                    .focused($focus, equals: .guideActivationView)
                    .defaultFocus($focus, .guideActivationView)
                    .onAppear {
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
            
//            // Global debug overlay (always on top)
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    Text("Focus: \(focus?.debugDescription ?? "nil") || Tab: \(appState.selectedTab.title) || isPaused: \(appState.isPlayerPaused ? "Yes" : "No") || isGuideShowing: \(appState.isGuideVisible ? "Yes" : "No") || ShowFavorites: \(appState.showFavoritesOnly ? "Yes" : "No")")
//                        .padding(10)
//                        .fontWeight(.bold)
//                        .background(Color(.gray))
//                        .focusable(false)
//                        .allowsHitTesting(false) 
//                }
//                .padding()
//            }
//            .zIndex(10000)
        }
        
#if os(tvOS)
        .onPlayPauseCommand {
            appState.isPlayerPaused.toggle()
        }
#endif

        .onChange(of: appState.isPlayerPaused, { _, newValue in
            updateShowPlayButtonToast(isPlayerPaused: newValue)
        })
        
        .onChange(of: scenePhase,  { _, newValue in
            // If app becomes not-active with the guide up, dismiss the guide.
            if newValue != .active && appState.isGuideVisible {
                appState.isGuideVisible = false
            }
        })
        
        .onChange(of: focus) { oldValue, newValue in
            if case .guide(let channelId, let col) = newValue, 0...1 ~= col {
                lastFocusedChannel = channelId
            }
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

extension MainAppContentView {
    
    /// Updates the visibility of the transient “Play” toast in response to the player's pause state.
    ///
    /// When the player becomes paused, this hides the toast immediately. When the player
    /// becomes unpaused (i.e., playing), this shows the toast for a short duration and then
    /// hides it automatically.
    ///
    /// Behavior:
    /// - Cancels any in-flight toast task to avoid overlapping timers or stale UI updates.
    /// - If `isPlayerPaused` is `true`, sets `showPlayButtonToast` to `false` right away.
    /// - If `isPlayerPaused` is `false`, starts a new `Task` on the main actor that:
    ///   - Sets `showPlayButtonToast` to `true`.
    ///   - Waits approximately 2 seconds.
    ///   - Checks for cancellation to ensure newer state changes take precedence.
    ///   - Sets `showPlayButtonToast` to `false` if not cancelled.
    ///
    /// Concurrency:
    /// - The task runs on the main actor because it mutates view state.
    /// - Cancellation is used to guarantee that only the latest state transition controls the toast.
    ///
    /// - Parameter isPlayerPaused: The current paused state of the player.
    ///   - Pass `true` to hide the toast immediately.
    ///   - Pass `false` to show the toast briefly and then hide it.
    private func updateShowPlayButtonToast(isPlayerPaused: Bool) {
        // Cancel any previous toast timer to prevent overlapping or stale state updates.
        fadeTask?.cancel()
        fadeTask = nil
        
        if isPlayerPaused == true {
            // When paused, ensure the toast is not visible.
            showPlayButtonToast = false
        } else {
            // When playing, show the toast briefly, then hide it unless cancelled by a new state change.
            fadeTask = Task { @MainActor in
                showPlayButtonToast = true
                do {
                    // Display the "Play" toast for 2 seconds.
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    // Ensure we weren't cancelled during the wait (e.g., state changed again).
                    try Task.checkCancellation()
                    showPlayButtonToast = false
                } catch {
                    // Task was cancelled; intentionally ignore to let the latest state win.
                }
            }
        }
    }
}

