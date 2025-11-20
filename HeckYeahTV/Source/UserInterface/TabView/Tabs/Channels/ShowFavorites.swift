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
    
    @Binding var appState: AppStateProvider
    var rightSwipeRedirectAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {

            HStack {
                
                // Title
                Text("Favorites")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
                    .focusable(false)
                
                // Button
                Button {
                    appState.showFavoritesOnly.toggle()
                } label: {
                    Label(appState.showFavoritesOnly ? "On" : "Off",
                          systemImage: appState.showFavoritesOnly ? "star.fill" : "star")
                    .font(.caption)
                    //.foregroundStyle(appState.showFavoritesOnly ? .yellow : .white)
                    .foregroundStyle(.yellow)
                }
#if os(tvOS)
                .onMoveCommand { direction in
                    if direction == .right  {
                        rightSwipeRedirectAction?()
                    }
                }
                // Add move handling to prevent automatic focus finding
                .onExitCommand {
                    // Block automatic exit behavior that might interfere
                }
#endif
                
                // Space the remainder
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

