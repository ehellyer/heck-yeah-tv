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
    
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    @Injected(\.analytics) private var analytics
    
    let focusNamespace: Namespace.ID
    @FocusState.Binding var focusedField: ChannelsContainer.FocusField?
    
    var body: some View {
        HStack {
            
            Text("Favorites")
                .font(.title2)
                .foregroundStyle(.white)
                .fontWeight(.bold)
            
            Button {
                swiftDataController.showFavoritesOnly.toggle()
                analytics.log(.favoritesFilterToggled(isEnabled: swiftDataController.showFavoritesOnly))
            } label: {
                HStack {
                    Label(swiftDataController.showFavoritesOnly ? "On" : "Off",
                          systemImage: swiftDataController.showFavoritesOnly ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .prefersDefaultFocus(in: focusNamespace)
            .focused($focusedField, equals: .showFavorites)
            .onMoveCommand { direction in
                if direction == .right  {
                    logDebug("Right swipe detected on ShowFavorites button")
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .focusSection()
        .padding(.horizontal, 20)
    }
}

#Preview {
    @Previewable @Namespace var namespace
    @Previewable @FocusState var focusField: ChannelsContainer.FocusField?
    
    return TVPreviewView() {
        ShowFavorites(
            focusNamespace: namespace,
            focusedField: $focusField
        )
    }
}
