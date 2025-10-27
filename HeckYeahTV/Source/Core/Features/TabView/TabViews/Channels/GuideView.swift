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
    @Environment(ChannelMap.self) private var channelMap
    @Binding var scrollToSelectedAndFocus: Bool
    @State private var rebuildChannelMapTask: Task<Void, Never>? = nil
    @State private var scrollThenFocusTask: Task<Void, Never>? = nil
    @State private var didEnsureSelectedVisible: Bool = false

    @State private var visibleChannelIds: Set<String> = []
    
    var body: some View {
        HStack(spacing: 0) {
#if os(tvOS)
            // Leading sentinel view "edge focus catcher" for swiping off the left side of the ScrollView.
            FocusSentinel(focus: $focus) {
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
                            let isChannelVisible = visibleChannelIds.contains(channelId)
                            GuideRowLazy(channelId: channelId,
                                         focus: $focus,
                                         appState: $appState,
                                         isVisible: isChannelVisible)
                            .id(channelId)
                            .onScrollVisibilityChange(threshold: 0.95) { isVisible in
                                if isVisible {
                                    visibleChannelIds.insert(channelId)
                                } else {
                                    visibleChannelIds.remove(channelId)
                                }
                            }
                            .onAppear {
                                visibleChannelIds.insert(channelId)
                            }
                            .onDisappear {
                                visibleChannelIds.remove(channelId)
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
                    scrollThenFocus(proxy: proxy, targetFocus: determinedFocusTarget)
                }
                
                .onChange(of: channelMap.totalCount) { _, _ in
                    scrollThenFocus(proxy: proxy, targetFocus: determinedFocusTarget)
                }
                
                .onChange(of: appState.showFavoritesOnly) { _, _ in
                    // Cancel any prior rebuild task if you want to coalesce rapid toggles
                    rebuildChannelMapTask?.cancel()
                    rebuildChannelMapTask = Task { @MainActor in
                        await rebuildChannelMap()
                    }
                }
                
                .onChange(of: scrollToSelectedAndFocus) { oldValue, newValue in
                    // Only updateFocus and scroll when in this state.
                    guard oldValue == false, newValue == true else {
                        return
                    }
                    scrollToSelectedAndFocus = false
                    scrollThenFocus(proxy: proxy, targetFocus: determinedFocusTarget)
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
            let cm = try await importer.buildChannelMap(showFavoritesOnly: SharedAppState.shared.showFavoritesOnly)
            await MainActor.run {
                channelMap.update(with: cm.map, totalCount: cm.map.count)
            }
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
    
    private func scrollThenFocus(proxy: ScrollViewProxy, targetFocus: FocusTarget?) {
        // Avoid multiple consecutive calls by cancelling the previous task.
        scrollThenFocusTask?.cancel()
        scrollThenFocusTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms - Small delay to debounce and also let redraw settle before starting the scroll.
            
            // If there is a selected channel, scroll to it.
            if let channelId = appState.selectedChannel {
                if let index = channelMap.map.firstIndex(of: channelId) {
                    withAnimation(.easeOut) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
            
            // Let scrolling/layout settle before setting the focus.
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            
            if !Task.isCancelled {
                focus = targetFocus
            }
        }
    }
}
