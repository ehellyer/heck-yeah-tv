//
//  GuideView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct GuideView: View {
    
    private let corner: CGFloat = 14

    @Environment(\.modelContext) private var viewContext
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    var channelMap: IPTVChannelMap
    
    @State private var onChannelListFocusTask: Task<Void, Never>? = nil
    @State private var ensureSelectedVisibleTask: Task<Void, Never>? = nil
    @State private var didEnsureSelectedVisible: Bool = false
    
    private var determinedFocusTarget: FocusTarget {
        if let channelId = appState.selectedChannel {
            return .guide(channelId: channelId, col: 1)
        } else {
            return .favoritesToggle
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Leading sentinel view "edge focus catcher" for swiping off the left side of the ScrollView.
            FocusSentinel(focus: $focus) {
                focus = .favoritesToggle
            }
            .frame(width: 1)

            // Main scrolling content
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 30) {
                        ForEach(0..<channelMap.totalCount, id: \.self) { index in
                            GuideRowLazy(channelId: channelMap.map[index], focus: $focus, appState: $appState)
                                .id(channelMap.map[index])
                                .zIndex(1)
                        }
                        
                        if channelMap.totalCount == 0 {
                            Text("No channels found.")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .zIndex(1)
                        }
                    }
                    // Shifts the rending of the rows to the right so the focus glow and row selection effects are not clipped on the left side.
                    .padding(.leading, 15)
                }
                .contentMargins(.vertical, 20)
                .background(Color.clear)
                
                .onAppear {
                    if let channelId = appState.selectedChannel {
                        withAnimation(nil) {
                            proxy.scrollTo(channelId, anchor: .center)
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            focus = determinedFocusTarget
                        }
                    }
                }
                
                .onChange(of: appState.showFavoritesOnly) { _, _ in
                    rebuildChannelMap()
                }
                
            }
        }
        .focusSection()
    }
}

private extension GuideView {
    private func rebuildChannelMap() {
        
        let container = DataPersistence.shared.container
        Task.detached(priority: .userInitiated) {
            do {
                logConsole("Is Main Thread: \(Thread.isMainThread)")
                let importer = ChannelImporter(container: container)
                try await importer.buildChannelMap(showFavoritesOnly: appState.showFavoritesOnly)
            } catch {
                logConsole("Error: \(error)")
            }
        }
//        Task { @MainActor in
//            do {
//                let importer = ChannelImporter(container: DataPersistence.shared.container)
//                try await importer.buildChannelMap(showFavoritesOnly: appState.showFavoritesOnly)
//            } catch {
//                logConsole("Error: \(error)")
//            }
//        }
    }
}

