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
    var focusRedirectAction: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 20) {
            
            // Title
            Text("Favorites")
                .font(.title2)
                .fontWeight(.bold)
                .focusable(false)
            
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
                logConsole("ShowFavorites redirect focus view caught focus.")
                focusRedirectAction?()
            }
            .frame(width: 60, height: 60)

            // Space the remainder
            Spacer()
        }
    }
}

