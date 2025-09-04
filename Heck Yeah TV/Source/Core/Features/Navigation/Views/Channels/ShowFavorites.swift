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
            
            Spacer()
        }
    }
}

//#Preview {
//    ShowFavorites(showFavoritesOnly: true)
//}
