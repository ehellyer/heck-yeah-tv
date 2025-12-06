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
    
    @Binding var appState: AppStateProvider
    
    @Environment(\.modelContext) private var viewContext
    @Environment(ChannelMap.self) private var channelMap
    
    @State private var rebuildChannelMapTask: Task<Void, Never>? = nil
    @State private var scrollToSelectedTask: Task<Void, Never>? = nil
    
    private let corner: CGFloat = 14
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(0..<channelMap.totalCount, id: \.self) { index in
                            let channelId = channelMap.map[index]
                            GuideRowLazy(channelId: channelId,
                                         appState: $appState)
                            .id(channelId)
                            .frame(height: 90) // Fixed height to prevent jumping
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                        }
                    }
                }
                .background(.clear)
                .contentMargins(.top, 10)
                .contentMargins(.bottom, 5)
#if os(tvOS)
                .focusSection()
#endif
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
            
            if channelMap.totalCount == 0 {
                Text("No channels available")
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)
                    .foregroundStyle(Color.white)
                    .fontDesign(Font.Design.rounded)
            }
        }
    }
}

//MARK: - GuideView extension

private extension GuideView {
    private func rebuildChannelMap() {
        // Cancel any prior rebuild task to coalesce rapid toggles
        rebuildChannelMapTask?.cancel()
        let container = viewContext.container
        rebuildChannelMapTask = Task.detached {
            do {
                try await Task.sleep(nanoseconds: debounceNS)
                try Task.checkCancellation()
                
                let importer = Importer(container: container)
                let cm = try await importer.buildChannelMap(appState: appState)
                await MainActor.run {
                    channelMap.update(with: cm.map)
                }
            } catch {
                // Task may have been cancelled.
                logError("Error: \(error)")
            }
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

//MARK: - PREVIEWS

#Preview("GuideView") {
    @Previewable @State var appState: AppStateProvider = SharedAppState.shared
    
    appState.selectedCountry = nil//"US"
    appState.showFavoritesOnly = false
    appState.selectedCategory = nil//"movies", "education", "comedy", "science", "documentary", "education"
    appState.searchTerm = nil//"mus"
    
    let mockData = MockDataPersistence(appState: appState)
    
    return GuideView(appState: $appState)
            .environment(\.modelContext, mockData.context)
            .environment(mockData.channelMap)
}
