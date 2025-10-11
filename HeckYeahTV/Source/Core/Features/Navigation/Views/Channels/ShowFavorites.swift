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

    var body: some View {
        HStack {
            Text("Favorites")
                .font(.title2)
                .fontWeight(.bold)
            Button {
                appState.showFavoritesOnly.toggle()
            } label: {
                Label(appState.showFavoritesOnly ? "On" : "Off",
                      systemImage: appState.showFavoritesOnly ? "star.fill" : "star")
                .font(.caption)
                .foregroundStyle(.yellow)
            }
            .focused($focus, equals: FocusTarget.favoritesToggle)
            Spacer()
        }
    }
}
