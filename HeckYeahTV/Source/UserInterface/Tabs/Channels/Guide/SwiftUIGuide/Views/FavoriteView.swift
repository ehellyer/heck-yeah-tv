//
//  FavoriteView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/2/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

import SwiftUI
import SwiftData

struct FavoriteView: View {
    
    @Binding var appState: AppStateProvider
    @State var channel: Channel?
    @Environment(\.modelContext) private var modelContext
    
    // Focus tracking for each button
    @FocusState private var focusedButton: FocusedButton?
    
    private let cornerRadius: CGFloat = AppStyle.cornerRadius
    
    private var isFavoriteChannel: Bool {
        return channel?.favorite?.isFavorite ?? false
    }
    
    private var isPlaying: Bool {
        guard let selectedChannelId = appState.selectedChannel else {
            return false
        }
        return selectedChannelId == channel?.id
    }

    var body: some View {
        Button {
            guard let channel else { return }
            if channel.favorite != nil {
                channel.favorite?.isFavorite.toggle()
                if modelContext.hasChanges {
                    try? modelContext.save()
                }
            } else {
                channel.favorite = Favorite(id: channel.id, isFavorite: true)
            }
        } label: {
            Image(systemName: isFavoriteChannel ? "star.fill" : "star")
                .scaleEffect(AppStyle.FavoritesView.scaleEffect)
                .foregroundStyle(isFavoriteChannel ? Color.yellow : Color.white)
                .frame(width: AppStyle.FavoritesView.width)
                .frame(height: AppStyle.FavoritesView.height)
        }
        .focused($focusedButton, equals: .favorite)
        .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                          cornerRadius: cornerRadius,
                                          isFocused: focusedButton == .favorite,
                                          isProgramNow: false))
    }
}

#Preview("Favorite View") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    
    let channel = swiftDataController.previewOnly_fetchChannel(at: 8)
    let selectedChannelId = swiftDataController.channelBundleMap.map[0]
    
    return TVPreviewView() {
        VStack {
            
            
            FavoriteView(appState: $appState,
                        channel: channel)
           
            
            FavoriteView(appState: $appState,
                        channel: channel)
            .redacted(reason: .placeholder)

            
        }
        .onAppear {
            appState.selectedChannel = selectedChannelId
        }
        
    }
}
