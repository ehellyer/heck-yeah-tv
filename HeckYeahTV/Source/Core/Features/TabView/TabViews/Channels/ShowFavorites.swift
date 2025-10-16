//
//  ShowFavorites.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/2/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct ShowFavorites: View {
    
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    var channelMap: IPTVChannelMap
    
    var body: some View {
        HStack(spacing: 20) {
            
            // Title
            Text("Favorites")
                .font(.title2)
                .fontWeight(.bold)
            
            // Button
            Button {
                appState.showFavoritesOnly.toggle()
            } label: {
                Label(appState.showFavoritesOnly ? "On" : "Off",
                      systemImage: appState.showFavoritesOnly ? "star.fill" : "star")
                .font(.caption)
                .foregroundStyle(.yellow)
            }
            .focused($focus, equals: FocusTarget.favoritesToggle)
            
            // Focus view for redirection
            FocusSentinel(focus: $focus) {
                focus = .guide(channelId: channelMap.map.first!, col: 1)
            }
            .frame(width: 60)
            .frame(height: 60)
            .focusable()
            .focused($focus, equals: FocusTarget.guide(channelId: String.randomString(length: 5), col: -34))

            // Space the remainder
            Spacer()
        }
        .focusSection()
    }
}

