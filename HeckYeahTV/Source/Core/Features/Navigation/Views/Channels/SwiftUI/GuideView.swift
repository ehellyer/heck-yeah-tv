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
    
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    @State private var onAppearTask: Task<Void, Never>? = nil
    
    @Environment(\.modelContext) private var modelContext
    
    // Paging/state
    @State private var channels: [IPTVChannel] = []
    @State private var isLoading: Bool = false
    @State private var hasMore: Bool = true
    @State private var offset: Int = 0
    private let pageSize: Int = 200 // Tune based on performance/memory
    
    // Sort and reusable predicates
    private static let sort = [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
    private static let favoritesPredicate = #Predicate<IPTVChannel> { $0.isFavorite == true }
    private static let playingPredicate = #Predicate<IPTVChannel> { $0.isPlaying }
    
    // Selected/playing channel id (fetched on demand)
    @State private var selectedChannelId: ChannelId? = nil
    
    private var onAppearTarget: FocusTarget {
        if let channelId = selectedChannelId {
            return .guide(channelId: channelId, col: 1)
        } else {
            return .favoritesToggle
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    ForEach(channels) { channel in
                        GuideRow(channel: channel, focus: $focus, appState: $appState)
                            .id(channel.id)
                            .onAppear {
                                // Infinite scroll trigger when approaching the end
                                if channel.id == channels.last?.id {
                                    loadMore()
                                }
                            }
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if !hasMore && channels.isEmpty {
                        Text("No channels found.")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }                
            }
            .contentMargins(.vertical, 20)
            .background(Color.clear)
            
            .onAppear {
                // Initial load if needed
                if channels.isEmpty {
                    resetAndLoad()
                } else {
                    // Refresh playing channel id for focus behavior
                    refreshPlayingChannelId()
                }
            }
            
            // When favorites toggle changes, reset paging and refetch with new predicate
            .onChange(of: appState.showFavoritesOnly) { _, _ in
                resetAndLoad()
            }
            
            // Cancel the onAppear task if we leave the tab
            .onChange(of: appState.selectedTab) { _, new in
                if new != TabSection.channels {
                    onAppearTask?.cancel()
                }
            }
            
            // Keep the focused row centered as focus moves
            .onChange(of: focus) { _, new in
                if case let .guide(id, _) = new {
                    withAnimation(.easeOut) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            
            // After loading page(s), optionally center on the playing channel and set focus
            .onChange(of: channels) { _, _ in
                // We only try to scroll/focus when we have a playing id
                guard let channelId = selectedChannelId else { return }
                // If that id is in the current dataset, center it
                if channels.contains(where: { $0.id == channelId }) {
                    onAppearTask?.cancel()
                    onAppearTask = Task { @MainActor in
                        withAnimation(.easeOut) {
                            proxy.scrollTo(channelId, anchor: .center)
                        }
                        do {
                            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 sec
                            try Task.checkCancellation()
                            withAnimation(.easeOut) {
                                appState.selectedTab = TabSection.channels
                                focus = onAppearTarget
                            }
                        } catch {
                            // Task cancelled
                        }
                    }
                }
            }
        }
        
        .background(Color.clear)
    }
}

// MARK: - Fetching
extension GuideView {
    
    private func resetAndLoad() {
        onAppearTask?.cancel()
        isLoading = false
        hasMore = true
        offset = 0
        channels.removeAll(keepingCapacity: true)
        refreshPlayingChannelId()
        loadMore()
    }
    
    private func loadMore() {
        guard !isLoading, hasMore else { return }
        isLoading = true
        
        // Capture current paging and filter flags
        let currentOffset = offset
        let currentPageSize = pageSize
        let showFavorites = appState.showFavoritesOnly
        
        // Build the descriptor off-main to avoid unnecessary main-thread work
        let descriptor: FetchDescriptor<IPTVChannel> = {
            var d = FetchDescriptor<IPTVChannel>(sortBy: GuideView.sort)
            d.fetchLimit = currentPageSize
            d.fetchOffset = currentOffset
            if showFavorites {
                d.predicate = GuideView.favoritesPredicate
            }
            return d
        }()
        
        // Perform the fetch on the main-actor bound context
        let page: [IPTVChannel] = (try? modelContext.fetch(descriptor)) ?? []
        
        // Update paging state on MainActor
        channels.append(contentsOf: page)
        hasMore = page.count == currentPageSize
        offset += page.count
        isLoading = false
    }
    
    private func refreshPlayingChannelId() {
        Task { @MainActor in
            let predicate = GuideView.playingPredicate
            var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
            descriptor.fetchLimit = 1
            descriptor.propertiesToFetch = [\.id]
            let result = try? modelContext.fetch(descriptor)
            selectedChannelId = result?.first?.id
        }
    }
}

