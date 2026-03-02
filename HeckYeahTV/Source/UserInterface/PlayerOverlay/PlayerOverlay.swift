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

            // Center playback controls
            HStack(spacing: 40) {
                // Play/Pause button
                controlButton(
                    systemImage: appState.isPlayerPaused ? "play.fill" : "pause.fill",
                    action: {
                        appState.isPlayerPaused.toggle()
                    }
                )
            }
            .padding(30)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

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
                            .glassEffect(.regular, in: Circle())
                    }
#if os(tvOS)
                    .buttonStyle(.card)
#else
                    .buttonStyle(.plain)
#endif
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    Button(action: volumeUp) {
                        Image(systemName: "speaker.plus.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                            .frame(width: 50, height: 50)
                            .glassEffect(.regular, in: Circle())
                    }
#if os(tvOS)
                    .buttonStyle(.card)
#else
                    .buttonStyle(.plain)
#endif
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
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
            .padding(.trailing, 30)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toastContainer()
    }
    
    // MARK: - Control Button
    
    private func controlButton(systemImage: String,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
        }
#if os(tvOS)
        .buttonStyle(.card)
#else
        .buttonStyle(.plain)
#endif
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
    
    appState.availableAudioTracks = [AudioTrack(id: 0,
                                                index: 0,
                                                name: "[English 5.1]")]
    
    return TVPreviewView {
        PlayerOverlay()
    }
}
