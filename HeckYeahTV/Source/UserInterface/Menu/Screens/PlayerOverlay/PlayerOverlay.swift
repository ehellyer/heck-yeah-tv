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
                        ForEach(appState.availableAudioTracks) { track in
                            Button(action: {
                                appState.selectedAudioTrackIndex = track.index
                            }) {
                                HStack {
                                    Text(track.name)
                                    if appState.selectedAudioTrackIndex == track.index {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "waveform.circle")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .glassEffect()
                    }
                    
                }
                
                // Closed caption selector button
                if !appState.availableSubtitleTracks.isEmpty {
                    let closedCaptionsEnabled: Bool = (appState.selectedSubtitleTrackIndex >= 0)
                    Menu {
                        // "Off" option
                        Button(action: {
                            appState.selectedSubtitleTrackIndex = -1
                        }) {
                            HStack {
                                Text("Off")
                                if not(closedCaptionsEnabled) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Available subtitle tracks
                        ForEach(appState.availableSubtitleTracks) { track in
                            Button(action: {
                                appState.selectedSubtitleTrackIndex = track.index
                            }) {
                                HStack {
                                    Text(track.name)
                                    if closedCaptionsEnabled && appState.selectedSubtitleTrackIndex == track.index {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: closedCaptionsEnabled ? "captions.bubble.fill" : "captions.bubble")
                            .font(.system(size: 24))
                            .foregroundStyle(closedCaptionsEnabled ? .blue : .white)
                            .frame(width: 50, height: 50)
                            .glassEffect()
                    }
                }
            }
            .padding(.trailing, 30)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toastContainer()
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
