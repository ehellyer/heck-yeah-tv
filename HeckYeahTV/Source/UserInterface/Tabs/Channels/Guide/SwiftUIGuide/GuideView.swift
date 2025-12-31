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
    
    @State private var swiftDataController: SwiftDataControllable = InjectedValues[\.swiftDataController]
    
    @State private var rebuildChannelBundleMapTask: Task<Void, Never>? = nil
    @State private var scrollToSelectedTask: Task<Void, Never>? = nil
    
    private let corner: CGFloat = 14
    private let hideGuideInfo: Bool = false
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading) {
                        ForEach(swiftDataController.channelBundleMap.map, id: \.self) { channelId in
                            GuideRowLazy(channelId: channelId,
                                         appState: $appState,
                                         hideGuideInfo: hideGuideInfo)
                            .id(channelId)
                        }
                    }
                }
                .background(.clear)
                .contentMargins(.top, 5)
                .contentMargins(.bottom, 5)
                .scrollIndicators(.visible)
#if os(tvOS)
                .focusSection()
#endif
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        scrollToSelected(proxy: proxy)
                    }
                }
                
                .onChange(of: swiftDataController.channelBundleMap.mapCount) { _, _ in
                    scrollToSelected(proxy: proxy)
                }
            }
            
            if swiftDataController.channelBundleMap.mapCount == 0 {
                
                if not(swiftDataController.showFavoritesOnly) {
                    VStack(spacing: 12) {
                        Image(systemName: "tv.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("No channels match criteria")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Try adjusting your filters")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                    .focusable(false)

                }
            }
        }
    }
}

//MARK: - GuideView extension

private extension GuideView {
    
    private func scrollToSelected(proxy: ScrollViewProxy) {
        // Avoid multiple consecutive calls by cancelling the previous task.
        scrollToSelectedTask?.cancel()
        scrollToSelectedTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: debounceNS)
            guard !Task.isCancelled else { return }
            
            if let channelId = appState.selectedChannel {
                proxy.scrollTo(channelId, anchor: .center)
            }
        }
    }
}

//MARK: - PREVIEWS

#if !os(tvOS)
#Preview("GuideView") {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()

    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        GuideView(appState: $appState)
            .modelContext(mockData.context)
    }
}
#endif
