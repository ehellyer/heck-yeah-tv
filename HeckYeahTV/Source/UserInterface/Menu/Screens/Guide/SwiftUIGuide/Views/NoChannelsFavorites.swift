//
//  NoChannelsFavorites.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/3/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NoChannelsFavorites: View {
    
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "star.slash.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
            Text("You have no favorite channels")
                .font(.headline)
                .foregroundStyle(.guideForegroundNoFocus)
            Text("Turn off the show favorites only filter, then add some channels as your favorites by tapping the star icon.")
                .font(.subheadline)
                .foregroundStyle(.guideForegroundNoFocus)
            
            Button {
                swiftDataController.showFavoritesOnly = false
            } label: {
                Text("Turn Off Favorites Only")
                    .font(.headline)
            }
            .padding(.top, 20)
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .padding(40)
        
        .focusable(false)
        .background(Color.clear)
    }
}

#Preview {
    NoChannelsFavorites()
}
