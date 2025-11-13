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
    @State private var showPlayPauseButton = false
    @State var appState: AppStateProvider = SharedAppState.shared
    
    @FocusState var hasFocus: Bool

    // Focus scopes (Namespace) for isolating focus between guide and activation views
    @Namespace private var activationScope

    var body: some View {
        // Alignment required to layout the play/pause button in the bottom left corner.
        ZStack(alignment: .bottomLeading)  {
         
            VLCPlayerView(appState: $appState)
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .focusable(false)

#if os(tvOS)
            if appState.isGuideVisible {
                TabContainerView(appState: $appState)
                    .transition(.opacity)
                    .background(Color.black.opacity(0.65))
            }
#endif
            
            if showPlayPauseButton {
                PlayPauseBadge()
            }
            
            if not(appState.isGuideVisible) {
                // Scope the activation view separately
                TabActivationView(appState: $appState)
#if os(tvOS)
                    .focusScope(activationScope)
#endif
                    .focused($hasFocus, equals: true)
                    .defaultFocus($hasFocus, true)
                    .onAppear {
                        hasFocus = true
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

        .onAppear {
            showPlayPauseButton = appState.isPlayerPaused
        }

#if os(macOS)
        // macOS: arrow keys re-show the guide
        .background( MacArrowKeyCatcher {
            withAnimation {
                appState.isGuideVisible = true
            }
        })
        
#endif
        
#if !os(tvOS)
        
        .sheet(isPresented: $appState.isGuideVisible) {
            NavigationStack {
                SectionView(appState: $appState)
                    .navigationTitle(TabSection.channels.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .padding(.top, 10)
                    .toolbar {
                        ToolbarItem {
                            Menu {
                                Picker("Category", selection: $appState.selectedTab) {
                                    ForEach(TabSection.allCases) { tabSection in
                                        Text(tabSection.title).tag(tabSection)
                                    }
                                }
                                .pickerStyle(.inline)
                                
                                Toggle(isOn: $appState.showFavoritesOnly) {
                                    Label("Favorites only", systemImage: "star.fill")
                                }
                                
                            } label: {
                                Label("Filter", systemImage: "slider.horizontal.3")
                            }
                        }
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                appState.isGuideVisible = false
                            }
                        }
                    }
            }
            
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
            }

        }
#endif
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
                do {
                    // Display the "Play" toast for 2 seconds.
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    try Task.checkCancellation()
                    showPlayPauseButton = false
                } catch {
                    // Task was cancelled; intentionally ignore to let the latest state win.
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Main View - Start Guide Visible") {
    @Previewable @State var _appState: any AppStateProvider = MockSharedAppState()
    let mockData = MockDataPersistence(appState: _appState)
    
    MainAppContentView(appState: _appState)
        .environment(\.modelContext, mockData.context)
        .environment(mockData.channelMap)
        .onAppear {
            _appState.selectedChannel = mockData.channelMap.map[2]
            _appState.isGuideVisible = true
            
        }
}
