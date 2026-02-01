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
            if let channelId {
                let channelBundleId = appState.selectedChannelBundle
                bundleEntry = swiftDataController.bundleEntry(for: channelId, channelBundleId: channelBundleId)
            }
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
    
    let channelId = swiftDataController.previewOnly_fetchChannel(at: 8).id
    let selectedChannelId = swiftDataController.channelBundleMap.map[0].channelId
    
    return TVPreviewView() {
        VStack {
            
            FavoriteView(channelId: channelId)
            
            FavoriteView(channelId: channelId)
            .redacted(reason: .placeholder)
            
        }
        .onAppear {
            appState.selectedChannel = selectedChannelId
        }
    }
}
