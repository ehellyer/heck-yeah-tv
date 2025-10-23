//
//  PlaybackBadge.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct PlaybackBadge: View {
    
    @State var isPlaying: Bool
        
    var body: some View {
        
        HStack(spacing: 8) {
            Image(systemName: isPlaying ? "play.fill" : "pause.fill")
                .imageScale(.medium)
            Text(isPlaying ? "Play" : "Paused")
                .font(.headline)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.15))
                )
        )
        
        .shadow(radius: 8, y: 4)
#if os(tvOS)
        .focusable(false)
#endif
        .accessibilityHidden(true)
        .allowsHitTesting(false)
        .padding(.leading, 50)
        .padding(.bottom, 50)
    }
}

#Preview("Play") {
    PlaybackBadge(isPlaying: true)
}

#Preview("Pause") {
    PlaybackBadge(isPlaying: false)
}
