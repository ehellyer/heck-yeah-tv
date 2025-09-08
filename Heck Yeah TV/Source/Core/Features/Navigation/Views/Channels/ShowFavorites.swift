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

    var body: some View {
        HStack {
            Text("Favorites")
                .font(.title2)
            Button {
                showFavoritesOnly.toggle()
            } label: {
               
                Label(showFavoritesOnly ? "On" : "Off",
                      systemImage: showFavoritesOnly ? "star.fill" : "star")
                .font(.caption)
                .foregroundStyle(showFavoritesOnly ? .yellow : .primary)
            }
#if os(tvOS)
            .focused($focus, equals: FocusTarget.favoritesToggle)
#endif
            Spacer()
        }
        .background(Color.black.opacity(0.01))
    }
}
//
//#if !os(tvOS)
//#Preview("On (constant)") {
//    ShowFavorites(showFavoritesOnly: .constant(true))
//        .padding()
//}
//
//#Preview("Off (constant)") {
//    ShowFavorites(showFavoritesOnly: .constant(false))
//        .padding()
//}
//
//#Preview("Interactive") {
//    ShowFavoritesPreview()
//}
//
//private struct ShowFavoritesPreview: View {
//    @State private var show = true
//    var body: some View {
//        ShowFavorites(showFavoritesOnly: $show)
//            .padding()
//    }
//}
//#endif
