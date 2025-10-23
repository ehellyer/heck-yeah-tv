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
    var upSwipeRedirectAction: (() -> Void)?
    var rightSwipeRedirectAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {

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
                .onMoveCommand { direction in
                    if direction == .up {
                        upSwipeRedirectAction?()
                    } else if direction == .right {
                        rightSwipeRedirectAction?()
                    }
                }
                
                // Space the remainder
                Spacer()
            }
        }
    }
}

