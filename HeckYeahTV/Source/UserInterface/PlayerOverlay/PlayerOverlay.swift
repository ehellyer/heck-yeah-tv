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
#if !os(tvOS)
                // Seek backward button
                controlButton(
                    systemImage: "gobackward.15",
                    action: seekBackward
                )
#endif
                
                // Play/Pause button
                controlButton(
                    systemImage: appState.isPlayerPaused ? "play.fill" : "pause.fill",
                    action: {
                        appState.isPlayerPaused.toggle()
                    }
                )
                
#if !os(tvOS)
                // Seek forward button
                controlButton(
                    systemImage: "goforward.15",
                    action: seekForward
                )
#endif
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white.opacity(0.25))
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
            
            Spacer()
            
#if os(tvOS)
            // Bottom hint for tvOS
            Text("Press Menu to show guide • Play/Pause to control playback")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.bottom, 30)
#endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private func seekForward() {
        NotificationCenter.default.post(name: .playerSeekForward, object: nil)
    }
    
    private func seekBackward() {
        NotificationCenter.default.post(name: .playerSeekBackward, object: nil)
    }
}

// MARK: - Notification Names



// MARK: - Preview

#Preview("Player Overlay") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    return ZStack {
        // Simulate video player background
        Color.black
            .ignoresSafeArea()
        
        PlayerOverlay()
    }
}
