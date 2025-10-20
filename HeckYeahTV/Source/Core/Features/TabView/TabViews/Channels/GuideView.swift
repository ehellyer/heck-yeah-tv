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
    @Binding var updateScrollViewFocus: Bool
    @State private var onChannelListFocusTask: Task<Void, Never>? = nil
    @State private var ensureSelectedVisibleTask: Task<Void, Never>? = nil
    @State private var didEnsureSelectedVisible: Bool = false
    @State private var visibleIndices: Set<Int> = []
    
    var body: some View {
        HStack(spacing: 0) {
#if os(tvOS)
            // Leading sentinel view "edge focus catcher" for swiping off the left side of the ScrollView.
            FocusSentinel(focus: $focus) {
                logConsole("LeftSideGuideView focus redirected to .favoritesToggle")
                focus = .favoritesToggle
            }
            .frame(width: 1)
#endif

            // Main scrolling content
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 30) {
                        ForEach(0..<channelMap.totalCount, id: \.self) { index in
                            let channelId = channelMap.map[index]
                            GuideRowLazy(channelId: channelId,
                                         focus: $focus,
                                         appState: $appState,
                                         isVisible: visibleIndices.contains(index))
                                .id(channelId)
                                .onScrollVisibilityChange(threshold: 1.0) { isVisible in
                                    //logConsole("Item \(index) visibility changed to: \(isVisible)")
                                    if isVisible {
                                        visibleIndices.insert(index)
                                    } else {
                                        visibleIndices.remove(index)
                                    }
                                }
                        }
                        
                        if channelMap.totalCount == 0 {
                            Text("No channels found.")
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    // Shift row to the right so the focus glow and row selection effects are not clipped on the left side.
                    .padding(.leading, 15)
                }
                .contentMargins(.vertical, 20)
                .scrollClipDisabled(false)
                
                .onAppear {
                    updateFocusAndScroll(proxy: proxy, targetFocus: determinedFocusTarget)
                }
                
                .onChange(of: channelMap.totalCount) { _, _ in
                    updateFocusAndScroll(proxy: proxy, targetFocus: determinedFocusTarget)
                }
                
                .onChange(of: appState.showFavoritesOnly) { _, _ in
                    // Cancel any prior rebuild task if you want to coalesce rapid toggles
                    onChannelListFocusTask?.cancel()
                    onChannelListFocusTask = Task { @MainActor in
                        await rebuildChannelMap()
                        logConsole("Channel Map rebuild completed.")
                    }
                }
                
                .onChange(of: updateScrollViewFocus) { oldValue, newValue in
                    guard oldValue == false, newValue == true else { return } // Only updateFocus and scroll when in this state.
                    updateScrollViewFocus = false
                    updateFocusAndScroll(proxy: proxy, targetFocus: determinedFocusTarget)
                }
            }
        }
    }
}

private extension GuideView {
    @MainActor
    func rebuildChannelMap() async {
        // Access the @MainActor DataPersistence singleton here
        let container = DataPersistence.shared.container
        do {
            // ChannelImporter is an actor; its async methods run in its isolation without blocking the main actor.
            let importer = ChannelImporter(container: container)
            try await importer.buildChannelMap(showFavoritesOnly: appState.showFavoritesOnly)
        } catch {
            logError("Error: \(error)")
        }
    }
    
    private var determinedFocusTarget: FocusTarget {
        if let channelId = appState.selectedChannel {
            return .guide(channelId: channelId, col: 1)
        } else {
            return .favoritesToggle
        }
    }
    
    private func updateFocusAndScroll(proxy: ScrollViewProxy, targetFocus: FocusTarget?) {
        // If there is a selected channel, scroll to it.
        if let channelId = appState.selectedChannel {
            withAnimation(.easeOut) {
                proxy.scrollTo(channelId, anchor: .center)
            }
        }
        
        // Set the focus view after a short delay using async Task to let layout settle.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            focus = targetFocus
        }
    }
}

