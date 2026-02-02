//
//  PlayPauseBadge.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct PlayPauseBadge: View {
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
    var body: some View {
        let isPlaying = not(appState.isPlayerPaused)
        HStack(spacing: 8) {
            Image(systemName: isPlaying ? "play.fill" : "pause.fill")
                .imageScale(.medium)
            Text(isPlaying ? "Play" : "Paused")
                .font(.headline)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.25))
                )
        )
        
        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
#if os(tvOS)
        .focusable(false)
#endif
        .accessibilityHidden(true)
        .allowsHitTesting(false)
        .padding(.leading, 50)
        .padding(.bottom, 50)
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState

    appState.isPlayerPaused = false
    return PlayPauseBadge()
}
