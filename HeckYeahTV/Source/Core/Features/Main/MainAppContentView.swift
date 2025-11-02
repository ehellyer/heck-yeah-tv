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
    
    @FocusState var focus: FocusTarget?
    
    // Focus scopes (Namespace) for isolating focus between guide and activation views
    @Namespace private var guideScope
    @Namespace private var activationScope

    var body: some View {
        // Alignment required to layout the play/pause button in the bottom left corner.
        ZStack(alignment: .bottomLeading)  {
            
            VLCPlayerView(appState: $appState)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .focusable(false)
                
            if appState.isGuideVisible {
                // Scope the entire guide UI to the same FocusState
                TabContainerView(focus: $focus, appState: $appState)
                    .transition(.opacity)
                    .background(Color.black.opacity(0.65))
#if os(tvOS)
                    .focusScope(guideScope)
#endif
            }
            
            if appState.isPlayerPaused || showPlayButtonToast {
                PlayPauseBadge(isPlaying: not(appState.isPlayerPaused))
            }
            
            if not(appState.isGuideVisible) {
                // Scope the activation view separately
                TabActivationView(appState: $appState)
#if os(tvOS)
                    .focusScope(activationScope)
#endif
                    .focused($focus, equals: .guideActivationView)
                    .defaultFocus($focus, .guideActivationView)
                    .onAppear {
                        focus = .guideActivationView
                    }
            }
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

