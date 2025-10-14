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
    @State private var onChannelListFocusTask: Task<Void, Never>? = nil
    @State private var ensureSelectedVisibleTask: Task<Void, Never>? = nil
    @State private var didEnsureSelectedVisible: Bool = false
    
    // Paging/state
    @State private var channels: [IPTVChannel] = []
    @State private var isLoadingChannels: Bool = false
    @State private var hasMore: Bool = true
    @State private var offset: Int = 0
    private let pageSize: Int = 200
    
    // Predicates and Sort
    private static var favoritesPredicate = #Predicate<IPTVChannel> { $0.isFavorite == true }
    static let isPlayingPredicate = #Predicate<IPTVChannel> { $0.isPlaying }
    private static var channelsDescriptor: FetchDescriptor<IPTVChannel> = FetchDescriptor<IPTVChannel>(sortBy: [SortDescriptor(\IPTVChannel.sortHint, order: .forward)])

    // Selected channel query (There should only ever be one channel in the store that is marked isPlaying.
    // Note: isPlaying is indexed.  (See IPTVChannel model definition)
    // Note: There is code on set that enforces and ensures only one channel isPlaying)
    @Query(filter: GuideView.isPlayingPredicate, sort: []) private var playingChannels: [IPTVChannel]
    private var selectedChannelId: ChannelId? { playingChannels.first?.id }
    
    private var determinedFocusTarget: FocusTarget {
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
                                // Page fault trigger, when at the end of current page, fetch more channels
                                if channel.id == channels.last?.id {
                                    loadMoreChannels()
                                }
                            }
                    }
                    
                    if isLoadingChannels {
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
                print("onAppear - resetAndLoad() called.")
                resetAndLoad()
            }
            
            .onChange(of: appState.showFavoritesOnly) { _, _ in
                print("onChange(of: appState.showFavoritesOnly - resetAndLoad() called.")
                resetAndLoad()
            }
            
            // Cancel tasks if we leave the tab
            .onChange(of: appState.selectedTab) { _, new in
                if new != TabSection.channels {
                    print("onChange(of: appState.selectedTab) - Cancel tasks")
                    onChannelListFocusTask?.cancel()
                    ensureSelectedVisibleTask?.cancel()
                }
            }

            //EJH - This fights the focus system responding to user input moving the focus around
//            // Keep the focused row centered as focus moves
//            .onChange(of: focus) { _, new in
//                if case let .guide(id, _) = new {
//                    withAnimation(.easeOut) {
//                        proxy.scrollTo(id, anchor: .center)
//                    }
//                }
//            }
            
            .onChange(of: channels) { _, _ in
                // Only attempt auto scroll/focus during the one-time ensure-visible phase
                guard didEnsureSelectedVisible == false else { return }
                
                onChannelListFocusTask?.cancel()
                onChannelListFocusTask = Task { @MainActor in
                    if let channelId = selectedChannelId {
                        withAnimation(.easeOut) {
                            proxy.scrollTo(channelId, anchor: .center)
                        }
                    }
                    do {
                        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 sec
                        try Task.checkCancellation()
                        withAnimation(.easeOut) {
                            appState.selectedTab = TabSection.channels
                            focus = determinedFocusTarget
                        }
                    } catch {
                        // Task cancelled
                    }
                }
                
                // If selectedChannel has been set but it is not in the current fetched set of data, fetch next page.
                if let channelId = selectedChannelId, not(channels.contains(where: { $0.id == channelId })) {
                    loadMoreChannels()
                    print("GuideView onChange(of: channels) - Selected channel not in channel list, loadMore() called")
                }
                
                // One-time ensure selected channel is visible by paging until found
                maybeEnsureSelectedVisible(proxy: proxy)
            }
        }
        
        .background(Color.clear)
    }
}

// MARK: - Fetching and ensure-visible logic
extension GuideView {
    
    private func resetAndLoad() {
        onChannelListFocusTask?.cancel()
        ensureSelectedVisibleTask?.cancel()
        didEnsureSelectedVisible = false
        isLoadingChannels = false
        hasMore = true
        offset = 0
        channels.removeAll(keepingCapacity: true)
        loadMoreChannels()
    }
    
    private func loadMoreChannels() {
        guard !isLoadingChannels, hasMore else {
            return
        }
        isLoadingChannels = true
        
        // Capture current paging and filter flags
        let currentOffset = offset
        let currentPageSize = pageSize
        let showFavorites = appState.showFavoritesOnly
        
        // Build the descriptor
        GuideView.channelsDescriptor.fetchLimit = currentPageSize
        GuideView.channelsDescriptor.fetchOffset = currentOffset
        GuideView.channelsDescriptor.predicate = (showFavorites ? GuideView.favoritesPredicate : nil)
        
        // Perform the fetch on the main-actor bound context
        let page: [IPTVChannel] = (try? viewContext.fetch(GuideView.channelsDescriptor)) ?? []
        
        // Update paging state on MainActor
        channels.append(contentsOf: page)
        hasMore = page.count == currentPageSize
        offset += page.count
        isLoadingChannels = false
    }
    
    // Schedules a one-time task that keeps paging until the selected channel is present, then scrolls and focuses it.
    private func maybeEnsureSelectedVisible(proxy: ScrollViewProxy) {
        guard !didEnsureSelectedVisible else { return }
        guard let targetId = selectedChannelId else {
            // No selection; mark as done
            didEnsureSelectedVisible = true
            return
        }
        // If already visible, just mark and ensure focus/scroll
        if channels.contains(where: { $0.id == targetId }) {
            didEnsureSelectedVisible = true
            onChannelListFocusTask?.cancel()
            onChannelListFocusTask = Task { @MainActor in
                withAnimation(.easeOut) {
                    proxy.scrollTo(targetId, anchor: .center)
                }
                do {
                    try await Task.sleep(nanoseconds: 300_000_000)
                    try Task.checkCancellation()
                    withAnimation(.easeOut) {
                        appState.selectedTab = .channels
                        focus = determinedFocusTarget
                    }
                } catch {
                    // Cancelled
                }
            }
            return
        }
        
        // Otherwise, keep loading pages until found or exhausted
        ensureSelectedVisibleTask?.cancel()
        ensureSelectedVisibleTask = Task { @MainActor in
            while !didEnsureSelectedVisible {
                try? Task.checkCancellation()
                
                // Stop if we can’t load more
                if !hasMore {
                    didEnsureSelectedVisible = true
                    break
                }
                
                // If a load is already in-flight, yield to next cycle
                if isLoadingChannels {
                    // Small delay to let current load finish
                    do {
                        try await Task.sleep(nanoseconds: 50_000_000)
                    } catch {
                        break
                    }
                    continue
                }
                
                // Load next page
                loadMoreChannels()
                
                // If now present, scroll and focus and mark done
                if channels.contains(where: { $0.id == targetId }) {
                    didEnsureSelectedVisible = true
                    withAnimation(.easeOut) {
                        proxy.scrollTo(targetId, anchor: .center)
                    }
                    // Small delay then focus
                    do {
                        try await Task.sleep(nanoseconds: 300_000_000)
                        try Task.checkCancellation()
                        withAnimation(.easeOut) {
                            appState.selectedTab = .channels
                            focus = determinedFocusTarget
                        }
                    } catch {
                        // Cancelled
                    }
                    break
                }
            }
        }
    }
}

