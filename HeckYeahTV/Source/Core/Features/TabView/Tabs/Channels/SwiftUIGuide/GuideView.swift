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

    @Binding var appState: AppStateProvider
    @Environment(\.modelContext) private var viewContext
    @Environment(ChannelMap.self) private var channelMap
    
    @State private var rebuildChannelMapTask: Task<Void, Never>? = nil
    @State private var scrollToSelectedTask: Task<Void, Never>? = nil
    
    var body: some View {
        // Main scrolling content
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 70) {
                    ForEach(0..<channelMap.totalCount, id: \.self) { index in
                        let channelId = channelMap.map[index]
                        GuideRowLazy(channelId: channelId,
                                     appState: $appState)
                        .id(channelId)
                    }
                    
                    if channelMap.totalCount == 0 {
                        Text("No channels found.")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
//            .scrollClipDisabled(false)
//            .scrollContentBackground(.hidden)
//            .background(Color.red)
            
            .onAppear {
                scrollToSelected(proxy: proxy)
            }
            
            .onChange(of: channelMap.totalCount) { _, _ in
                scrollToSelected(proxy: proxy)
            }
            
            .onChange(of: appState.showFavoritesOnly) { _, _ in
                rebuildChannelMap()
            }
        }
    }
}


private extension GuideView {
    private func rebuildChannelMap() {
        // Cancel any prior rebuild task if you want to coalesce rapid toggles
        rebuildChannelMapTask?.cancel()
        let container = DataPersistence.shared.container
        rebuildChannelMapTask = Task.detached {
            do {
                try await Task.sleep(nanoseconds: debounceNS)
                try Task.checkCancellation()
                
                let importer = ChannelImporter(container: container)
                let cm = try await importer.buildChannelMap(showFavoritesOnly: SharedAppState.shared.showFavoritesOnly)
                await MainActor.run {
                    channelMap.update(with: cm.map)
                }
            } catch {
                //Task may have been cancelled.
                logError("Error: \(error)")
            }
        }

        // Access the @MainActor DataPersistence singleton here
    }
    
    private var determinedFocusTarget: FocusTarget {
        if let channelId = appState.selectedChannel {
            return .guide(channelId: channelId, col: 1)
        } else {
            return .favoritesToggle
        }
    }
    
    private func scrollToSelected(proxy: ScrollViewProxy) {
        // Avoid multiple consecutive calls by cancelling the previous task.
        scrollToSelectedTask?.cancel()
        scrollToSelectedTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: debounceNS)
                try Task.checkCancellation()
                
                if let channelId = appState.selectedChannel {
                    if let index = channelMap.map.firstIndex(of: channelId) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            } catch {
                //Task may have been cancelled.
                logError("Error: \(error)")
            }
        }
    }
}

#Preview("GuideView") {
    
    @Previewable @State var appState: AppStateProvider = SharedAppState.shared
    
    let mockData = MockDataPersistence(appState: appState)
    
    GuideView(appState: $appState)
        .environment(\.modelContext, mockData.context)
        .environment(mockData.channelMap)
}
