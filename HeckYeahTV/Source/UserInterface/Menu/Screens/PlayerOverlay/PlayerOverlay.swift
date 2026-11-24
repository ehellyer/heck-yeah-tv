//
//  PlayerOverlay.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/5/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct PlayerOverlay: View {
    
    // MARK: - State
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    @Injected(\.analytics) private var analytics

    // MARK: - Body
    
    var body: some View {
        VStack {

            Spacer()

            // Play/Pause button
            Button(action: {
                appState.isPlayerPaused.toggle()
            }) {
                Image(systemName: appState.isPlayerPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .padding(20)
                    .glassEffect()
            }
            .buttonStyle(.plain)

            Spacer()

            // Bottom controls (volume, audio track selector, and closed caption selector)
            HStack(spacing: 20) {
                // Volume controls (left side)
                HStack(spacing: 15) {
                    Button(action: volumeDown) {
                        Image(systemName: "speaker.minus.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .glassEffect()
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: volumeUp) {
                        Image(systemName: "speaker.plus.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .glassEffect()
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: toggleMute) {
                        Image(systemName: appState.playerVolume == 0 ? "speaker.slash.circle" : "speaker.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .glassEffect()
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 30)
                
                Spacer()
                
                // Audio track selector button
                if !appState.availableAudioTracks.isEmpty {
                    Menu {
                        // Inline Picker gives native selection checkmarks on iOS, tvOS and macOS.
                        // (A trailing checkmark Image in a Button label is not shown as a checkmark in macOS menus.)
                        Picker("Audio Track", selection: audioTrackSelection) {
                            ForEach(appState.availableAudioTracks) { track in
                                Text(track.name)
                                    .tag(track.index)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .glassEffect()
                    }
                    .menuIndicator(.hidden) // macOS otherwise draws a dropdown chevron beside the icon
#if os(macOS)
                    // macOS otherwise renders the menu as a bordered button (a rect behind the round icon).
                    .menuStyle(.button)
                    .buttonStyle(.plain)
#endif

                }
                
                // Closed caption selector button
                if !appState.availableSubtitleTracks.isEmpty {
                    let closedCaptionsEnabled: Bool = (appState.selectedSubtitleTrackIndex >= 0)
                    Menu {
                        // Inline Picker gives native selection checkmarks on iOS, tvOS and macOS.
                        // "Off" is tag -1, matching selectedSubtitleTrackIndex when subtitles are disabled.
                        Picker("Subtitles", selection: subtitleTrackSelection) {
                            Text("Off")
                                .tag(-1)
                            ForEach(appState.availableSubtitleTracks) { track in
                                Text(track.name)
                                    .tag(track.index)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Image(systemName: closedCaptionsEnabled ? "captions.bubble.fill" : "captions.bubble")
                            .font(.system(size: 24))
                            .foregroundStyle(closedCaptionsEnabled ? .blue : .white)
                            .frame(width: 50, height: 50)
                            .glassEffect()
                    }
                    .menuIndicator(.hidden) // macOS otherwise draws a dropdown chevron beside the icon
#if os(macOS)
                    // macOS otherwise renders the menu as a bordered button (a rect behind the round icon).
                    .menuStyle(.button)
                    .buttonStyle(.plain)
#endif
                }
            }
            .padding(.trailing, 30)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toastContainer()
    }
    
    // MARK: - Track selection bindings

    /// Audio track Picker selection. Logs analytics when the user picks a different track.
    private var audioTrackSelection: Binding<Int> {
        Binding(
            get: { appState.selectedAudioTrackIndex },
            set: { newIndex in
                guard newIndex != appState.selectedAudioTrackIndex else { return }
                appState.selectedAudioTrackIndex = newIndex
                if let channelId = swiftDataController.selectedChannel?.id,
                   let track = appState.availableAudioTracks.first(where: { $0.index == newIndex }) {
                    analytics.log(.audioTrackChanged(channelId: channelId, trackName: track.name))
                }
            }
        )
    }

    /// Subtitle Picker selection (-1 = Off). Logs enabled/changed/disabled analytics like the previous menu buttons.
    private var subtitleTrackSelection: Binding<Int> {
        Binding(
            get: { appState.selectedSubtitleTrackIndex },
            set: { newIndex in
                let previousIndex = appState.selectedSubtitleTrackIndex
                guard newIndex != previousIndex else { return }
                appState.selectedSubtitleTrackIndex = newIndex
                guard let channelId = swiftDataController.selectedChannel?.id else { return }
                if newIndex < 0 {
                    analytics.log(.subtitlesDisabled(channelId: channelId))
                } else if let track = appState.availableSubtitleTracks.first(where: { $0.index == newIndex }) {
                    if previousIndex < 0 {
                        analytics.log(.subtitlesEnabled(channelId: channelId, trackName: track.name))
                    } else {
                        analytics.log(.subtitleTrackChanged(channelId: channelId, trackName: track.name))
                    }
                }
            }
        )
    }

    // MARK: - Actions

    private func volumeUp() {
        // If currently muted, restore to pre-muted volume before increasing
        if appState.playerVolume == 0, let preMutedVolume = appState.preMutedVolume {
            appState.playerVolume = preMutedVolume
            appState.preMutedVolume = nil
            showVolumeToast(preMutedVolume)
        } else {
            let newVolume = min(appState.playerVolume + 10, 200)
            appState.playerVolume = newVolume
            showVolumeToast(newVolume)
        }
    }
    
    private func volumeDown() {
        let newVolume = max(appState.playerVolume - 10, 0)
        appState.playerVolume = newVolume
        showVolumeToast(newVolume)
    }
    
    private func toggleMute() {
        if appState.playerVolume == 0 {
            // Unmute: restore to pre-muted volume or default to 100
            let restoredVolume = appState.preMutedVolume ?? 100
            appState.playerVolume = restoredVolume
            appState.preMutedVolume = nil
            showVolumeToast(restoredVolume)
        } else {
            // Mute: save current volume and set to 0
            appState.preMutedVolume = appState.playerVolume
            appState.playerVolume = 0
            showVolumeToast(0)
        }
    }
    
    private func showVolumeToast(_ volume: Int32) {
        ToastManager.shared.show("Volume \(volume)%")
    }
}

// MARK: - Preview

#Preview("Player Overlay") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    appState.availableSubtitleTracks = [TrackItem(id: 0,
                                                  index: 0,
                                                  name: "Closed Captions")]
    
    appState.availableAudioTracks = [TrackItem(id: 0,
                                               index: 0,
                                               name: "[English 5.1]")]
    
    return TVPreviewView {
        PlayerOverlay()
    }
}
