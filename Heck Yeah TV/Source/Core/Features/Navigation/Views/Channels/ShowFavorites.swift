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
//            Text(showFavoritesOnly ? "Favorites" : "All Channels")
//                .font(.title)
//                .fontWeight(.bold)
//            Spacer()
//            Picker(selection: $showFavoritesOnly, label: Text("Picker"), content: {
//                Text("All")
//                    .tag(false)
//                Text("Favorites")
//                    .tag(true)
//            })
//            .padding(.vertical, 10)
//            .labelsHidden()
//            .pickerStyle(SegmentedPickerStyle())
//            .fixedSize()
//            .focused($focus, equals: FocusTarget.favoritesToggle)
            
            Text("Favorites")
                .font(.title)
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
    }
}
