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
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var fadeTask: Task<Void, Never>?
    @State private var showPlayPauseButton = false
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
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
            VLCPlayerView()
                .ignoresSafeArea()
                .accessibilityHidden(true)
                .allowsHitTesting(false)
                .focusable(false)
            

//#if os(tvOS)
//            if showPlayPauseButton {
//                PlayPauseBadge()
//            }
//#endif
            
            if not(appState.showAppMenu) {
                MenuActivationView()
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
        
        .fullScreenCover(isPresented: $appState.showAppMenu) {
//            AppMenuView()
            MenuPickerView()
                .background(TransparentBackground())
                .presentationBackground(.clear)
                .zIndex(5)
                .background(Color.guideTransparency)
#if os(tvOS)
                .focusScope(guideScope)
                .focused($focusedSection, equals: .guide)
                .defaultFocus($focusedSection, .guide)
                .disabled(appState.showProgramDetailCarousel != nil) // Prevents focus jumping from ChannelProgramsCarousel to Guide in the background.
                .onAppear {
                    focusedSection = .guide
                }

#endif
                .overlay {
                    
                    // Channel Programs Carousel
                    if let channelProgram = appState.showProgramDetailCarousel {
                        ChannelProgramsCarousel(channelProgram: channelProgram)
                            .zIndex(10)
#if os(tvOS)
                            .focusScope(channelProgramsScope)
                            .focused($focusedSection, equals: .channelPrograms)
                            .defaultFocus($focusedSection, .channelPrograms)
                            .onAppear {
                                focusedSection = .channelPrograms
                            }
                            .onDisappear {
                                //We can only get to the carousel from the guide, so return focus to guide.
                                focusedSection = .guide
                            }
#endif
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
                appState.showAppMenu = false        // If presented, hides app menu.
                appState.showProgramDetailCarousel = nil  // If presented, hides program carousel.
            }
        })
        
        .onAppear {
            showPlayPauseButton = appState.isPlayerPaused
        }
    }
}


struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        Task { @MainActor in
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
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

#Preview("Light Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController

///    let selectedChannelId = swiftDataController.channelBundleMap.map[3]

    return ZStack {
        //Color.yellow.ignoresSafeArea()
        
        MainAppContentView()
            .background(Color.clear)
            .onAppear {
                //appState.selectedBundleChannel = selectedChannelId
                appState.showAppMenu = false
            }
            .environment(\.colorScheme, .light)
    }
}

#Preview("Dark Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController

///    let selectedChannelId = swiftDataController.channelBundleMap.map[3]

    return ZStack {
        //Color.yellow.ignoresSafeArea()
        
        MainAppContentView()
            .background(Color.clear)
            .onAppear {
                //appState.selectedBundleChannel = selectedChannelId
                appState.showAppMenu = false
            }
            .environment(\.colorScheme, .dark)
    }
}

