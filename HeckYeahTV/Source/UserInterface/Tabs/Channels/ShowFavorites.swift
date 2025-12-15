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
    
    @State private var swiftDataController: SwiftDataControllable = InjectedValues[\.swiftDataController]
    
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
                    swiftDataController.showFavoritesOnly.toggle()
                } label: {
                    Label(swiftDataController.showFavoritesOnly ? "On" : "Off",
                          systemImage: swiftDataController.showFavoritesOnly ? "star.fill" : "star")
                    .font(.caption)
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

