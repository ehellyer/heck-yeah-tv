//
//  PlaybackBadge.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct PlaybackBadge: View {
    let text: String
    let systemName: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemName)
                .imageScale(.medium)
            Text(text)
                .font(.headline) 
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            // Material on tvOS/macOS/iOS; falls back to opaque if needed
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.15))
                )
        )
        
        .shadow(radius: 8, y: 4)
    }
}

#Preview("Play") {
    PlaybackBadge(text: "Play", systemName: "play.fill")
}

#Preview("Pause") {
    PlaybackBadge(text: "Pause", systemName: "pause.fill")
}
