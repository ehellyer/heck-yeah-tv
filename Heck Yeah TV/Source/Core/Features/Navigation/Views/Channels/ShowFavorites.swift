//
//  ShowFavorites.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/2/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ShowFavorites: View {
    
    @Environment(GuideStore.self) var guideStore
    
    private var isOn: Binding<Bool> {
        Binding(
            get: { guideStore.showFavoritesOnly },
            set: { guideStore.showFavoritesOnly = $0 }
        )
    }
    
    var body: some View {
        HStack {
            Text("Favorites")
                .font(.title)
            Button {
                guideStore.showFavoritesOnly.toggle()
            } label: {
                let isFavorite = guideStore.showFavoritesOnly
                Label(isFavorite ? "On" : "Off",
                      systemImage: isFavorite ? "star.fill" : "star")
                .foregroundStyle(isFavorite ? .yellow : .primary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ShowFavorites().environment(GuideStore())
}
