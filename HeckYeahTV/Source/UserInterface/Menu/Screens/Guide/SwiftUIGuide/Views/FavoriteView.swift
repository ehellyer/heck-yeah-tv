//
//  FavoriteView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/2/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct FavoriteView: View {
    
    let channelId: ChannelId?
    
    @State private var bundleEntry: BundleEntry? = nil
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    
    // Focus tracking for each button
    @FocusState private var focusedButton: FocusedButton?
    
    private let cornerRadius: CGFloat = AppStyle.cornerRadius
    
    private var isPlaying: Bool {
        let selectedChannelId = appState.selectedChannel
        return selectedChannelId != nil && selectedChannelId == channelId
    }
    
    var body: some View {
        Button {
            bundleEntry?.isFavorite.toggle()
            do {
                try swiftDataController.viewContext.saveChangesIfNeeded()
            } catch {
                logError("Failed to save favorite state: \(error)")
            }
        } label: {
            let isFavorite: Bool = bundleEntry?.isFavorite ?? false
            
            Image(systemName: isFavorite ? "star.fill" : "star")
                .scaleEffect(AppStyle.FavoritesView.scaleEffect)
                .foregroundStyle(isFavorite ? Color.yellow : Color.white)
                .frame(width: AppStyle.FavoritesView.width)
                .frame(height: AppStyle.FavoritesView.height)
        }
        .focused($focusedButton, equals: .favorite)
        .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                          cornerRadius: cornerRadius,
                                          isFocused: focusedButton == .favorite,
                                          isProgramNow: false))
        .onAppear {
            guard let channelId else { return }
            let bundleEntryId = swiftDataController.channelBundleMap.map[channelId]
            bundleEntry = swiftDataController.bundleEntry(for: bundleEntryId)
        }
    }
}

#Preview("Favorite View") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.channelBundleMap.channelIds[8]
    let selectedChannelId = swiftDataController.channelBundleMap.channelIds[0]
    
    return TVPreviewView() {
        VStack {
            
            FavoriteView(channelId: nil)
            
            FavoriteView(channelId: channelId)
            
            FavoriteView(channelId: channelId)
            .redacted(reason: .placeholder)
            
        }
        .onAppear {
            appState.selectedChannel = selectedChannelId
        }
    }
}
