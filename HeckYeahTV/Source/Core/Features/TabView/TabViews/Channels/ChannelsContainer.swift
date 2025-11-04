//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelsContainer: View {
    
    @Binding var appState: SharedAppState
    @Environment(ChannelMap.self) private var channelMap
    
    @State private var scrollToSelectedAndFocus: Bool = false
    @State private var rebuildChannelMapTask: Task<Void, Never>? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            ShowFavorites(appState: $appState,
                          upSwipeRedirectAction: {
                //Do nothing.
            },
                          rightSwipeRedirectAction: {
                scrollToSelectedAndFocus = true
            })
#if os(tvOS)
            .focusSection()
#endif
            
//            GuideView(focus: $focus, appState: $appState, scrollToSelectedAndFocus: $scrollToSelectedAndFocus)
            GuideViewRepresentable(appState: $appState)
                .onAppear {
                    logDebug("🎯 GuideViewRepresentable appeared")
                }
            
                .onChange(of: appState.showFavoritesOnly) { _, _ in
                    //Debounce rebuilding of channel map.
                    rebuildChannelMapTask?.cancel()
                    rebuildChannelMapTask = Task { @MainActor in
                        do {
                            try await Task.sleep(nanoseconds: 100_000_000)
                            try Task.checkCancellation()
                            await rebuildChannelMap()
                        } catch {
                            //Task cancelled.
                        }
                    }
                }
        }
    }
}

extension ChannelsContainer {
    func rebuildChannelMap() async {
        // Access the @MainActor DataPersistence singleton here
        let container = DataPersistence.shared.container
        do {
            // ChannelImporter is an actor; its async methods run in its isolation without blocking the main actor.
            let importer = ChannelImporter(container: container)
            let cm = try await importer.buildChannelMap(showFavoritesOnly: SharedAppState.shared.showFavoritesOnly)
            await MainActor.run {
                channelMap.update(with: cm.map, totalCount: cm.map.count)
            }
        } catch {
            logError("Error: \(error)")
        }
    }
}
