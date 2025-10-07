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
    private var isFocused: Bool { focus == .favoritesToggle }
    
    @State private var appState: SharedAppState = SharedAppState()
    
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


#Preview("On (constant)") {
    ShowFavoritesPreview()
}
#Preview("Off (constant)") {
    ShowFavoritesPreview()
}

private struct ShowFavoritesPreview: View {
    @FocusState private var focus: FocusTarget?
    var body: some View {
        ShowFavorites(focus: $focus)
            .padding()
            .defaultFocus($focus, .favoritesToggle)
            .onAppear { focus = .favoritesToggle }
    }
}
