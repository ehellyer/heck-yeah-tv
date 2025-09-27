//
//  ShowFavorites.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/2/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ShowFavorites: View {
    
    @Binding var showFavoritesOnly: Bool
    @FocusState.Binding var focus: FocusTarget?
    
    private var isFocused: Bool { focus == .favoritesToggle }
    
    var body: some View {
        HStack {
            Text("Favorites")
                .font(.title2)
                .fontWeight(.bold)
            Button {
                showFavoritesOnly.toggle()
            } label: {
                Label(showFavoritesOnly ? "On" : "Off",
                      systemImage: showFavoritesOnly ? "star.fill" : "star")
                .font(.caption)
                .foregroundStyle(.yellow)
            }
            .focused($focus, equals: FocusTarget.favoritesToggle)
            Spacer()
        }
    }
}


#Preview("On (constant)") {
    ShowFavoritesPreview(show: true)
}
#Preview("Off (constant)") {
    ShowFavoritesPreview(show: false)
}

private struct ShowFavoritesPreview: View {
    @State var show: Bool
    @FocusState private var focus: FocusTarget?
    var body: some View {
        ShowFavorites(showFavoritesOnly: $show, focus: $focus)
            .padding()
            .defaultFocus($focus, .favoritesToggle)
            .onAppear { focus = .favoritesToggle }
    }
}
