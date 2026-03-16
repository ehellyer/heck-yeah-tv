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
                    Menu {
                        // "Off" option
                        Button(action: {
                            appState.closedCaptionsEnabled = false
                            appState.selectedSubtitleTrackIndex = nil
                        }) {
                            HStack {
                                Text("Off")
                                if !appState.closedCaptionsEnabled {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Available subtitle tracks
                        ForEach(appState.availableSubtitleTracks) { track in
                            Button(action: {
                                appState.closedCaptionsEnabled = true
                                appState.selectedSubtitleTrackIndex = track.index
                            }) {
                                HStack {
                                    Text(track.name)
                                    if appState.closedCaptionsEnabled && appState.selectedSubtitleTrackIndex == track.index {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: appState.closedCaptionsEnabled ? "captions.bubble.fill" : "captions.bubble")
                            .font(.system(size: 24))
                            .foregroundStyle(appState.closedCaptionsEnabled ? .blue : .white)
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
        let newVolume = min(appState.playerVolume + 10, 200)
        appState.playerVolume = newVolume
        showVolumeToast(newVolume)
    }
    
    private func volumeDown() {
        let newVolume = max(appState.playerVolume - 10, 0)
        appState.playerVolume = newVolume
        showVolumeToast(newVolume)
    }
    
    private func showVolumeToast(_ volume: Int32) {
        ToastManager.shared.show("Volume \(volume)%")
    }
}

// MARK: - Preview

#Preview("Player Overlay") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    appState.availableSubtitleTracks = [SubtitleTrack(id: 0,
                                                      index: 0,
                                                      name: "Closed Captions")]
    
    appState.availableAudioTracks = [AudioTrack(id: 0,
                                                index: 0,
                                                name: "[English 5.1]")]
    
    return TVPreviewView {
        PlayerOverlay()
    }
}
