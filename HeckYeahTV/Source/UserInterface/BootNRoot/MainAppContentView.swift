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
    
    // Note: This is not private so that it can be overridden in the #Preview with a mock implementation
    @State var appState: AppStateProvider = SharedAppState.shared
    
    @State private var fadeTask: Task<Void, Never>?
    @State private var showPlayPauseButton = false
    @State private var swiftDataController: SwiftDataControllable = InjectedValues[\.swiftDataController]
    @Environment(\.scenePhase) private var scenePhase
    
    // Focus states
    enum FocusedSection: Hashable {
        case activationView
        case guide
        case channelPrograms
    }
    
    @FocusState private var focusedSection: FocusedSection?
    
    // Focus scopes (Namespace) for isolating focus between activation views, guide and channel programs
    @Namespace private var activationScope
    @Namespace private var guideScope
    @Namespace private var channelProgramsScope
    
    var body: some View {
        // Alignment required to layout the play/pause button in the bottom left corner.
        ZStack(alignment: .bottomLeading)  {
            
            // Stream Player
            VLCPlayerView(appState: $appState)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .focusable(false)
            
#if os(tvOS)
            // App Menu for tvOS
            if appState.showAppMenu {
                MenuTabView(appState: $appState)
                    .transition(.opacity)
                    .background(Color.guideTransparency)
                    .focusScope(guideScope)
                    .focused($focusedSection, equals: .guide)
                    .defaultFocus($focusedSection, .guide)
                    .focusable(appState.showChannelPrograms == nil)             // Disable focus to prevent focus jumping to this view.
                    .allowsHitTesting(appState.showChannelPrograms == nil)      // Disable focus to prevent focus jumping to this view.
                    .accessibilityHidden(appState.showChannelPrograms != nil)   // Disable focus to prevent focus jumping to this view.
                    .onAppear {
                        focusedSection = .guide
                    }
            }
#else
            // App Menu for iOS/macOS
            if appState.showAppMenu {
                MainMenu(appState: $appState)
            }
#endif
            
            // Channel Programs Carousel
            if let channelProgram = appState.showChannelPrograms,
               let _channel = try? swiftDataController.channel(for: channelProgram.channelId) {
                
                let _programs = swiftDataController.channelPrograms(for: channelProgram.channelId)
                ChannelProgramsCarousel(appState: $appState,
                                        channelPrograms: _programs,
                                        startOnProgram: channelProgram.id,
                                        channel: _channel)
                .zIndex(10)
#if os(tvOS)
                .focusScope(channelProgramsScope)
                .focused($focusedSection, equals: .channelPrograms)
                .defaultFocus($focusedSection, .channelPrograms)
                .onAppear {
                    focusedSection = .channelPrograms
                }
                .onDisappear {
                    focusedSection = .guide
                }
#endif
            }
            
            
            if showPlayPauseButton {
                PlayPauseBadge()
            }
            
            if not(appState.showAppMenu) {
                MenuActivationView(appState: $appState)
#if os(tvOS)
                    .focusScope(activationScope)
#endif
                    .focused($focusedSection, equals: .activationView)
                    .defaultFocus($focusedSection, .activationView)
                    .onAppear {
                        focusedSection = .activationView
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
            // If app becomes not-active with the app navigation visible, dismiss the app navigation.
            if newValue != .active && appState.showAppMenu {
                appState.showAppMenu = false
            }
        })
        
        .onAppear {
            showPlayPauseButton = appState.isPlayerPaused
        }
    }
}


extension MainAppContentView {
    
    /// Updates the visibility of the transient “Play” toast in response to the player's pause state.
    ///
    /// When the player becomes paused, this presents the toast permanently. When the player
    /// becomes unpaused (i.e., playing), this shows the toast for a short duration and then
    /// hides it automatically.
    ///
    /// Behavior:
    /// - Cancels any in-flight toast task to avoid overlapping timers or stale UI updates.
    /// - If `isPlayerPaused` is `true`, sets `showPlayPauseButton` to `true` right away.
    /// - If `isPlayerPaused` is `false`, starts a new `Task` on the main actor that:
    ///   - Sets `showPlayPauseButton` to `true`.
    ///   - Waits approximately 2 seconds.
    ///   - Checks for cancellation to ensure newer state changes take precedence.
    ///   - Sets `showPlayPauseButton` to `false` if not cancelled.
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
            // When paused, ensure the toast is visible.
            showPlayPauseButton = true
        } else {
            // When playing, show the toast briefly, then hide it unless cancelled by a new state change.
            fadeTask = Task { @MainActor in
                showPlayPauseButton = true
                // Display the "Play" toast for 2 seconds.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard !Task.isCancelled else { return }
                showPlayPauseButton = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Main View") {
    @Previewable @State var _appState: any AppStateProvider = MockSharedAppState()

    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
//    let selectedChannelId = swiftDataController.channelBundleMap.map[3]
    
    return MainAppContentView(appState: _appState)
        .modelContext(mockData.viewContext)
        .onAppear {
            //_appState.selectedChannel = selectedChannelId
            _appState.showAppMenu = false
        }
}
