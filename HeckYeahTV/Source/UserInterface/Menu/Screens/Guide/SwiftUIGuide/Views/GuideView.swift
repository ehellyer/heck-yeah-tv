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
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var rebuildChannelBundleMapTask: Task<Void, Never>? = nil
    @State private var scrollToSelectedTask: Task<Void, Never>? = nil
    @State private var guideWidth: CGFloat = 20 // Will update dynamically
    
    private let corner: CGFloat = 14
    private let hideGuideInfo: Bool = false
    
    private func isHorizontallyCompact(width: CGFloat) -> Bool {
        // Behave as compact when showing recents view.  This prevents the guide info to the right.
        if hideGuideInfo {
            return true
        }
        return width < 600
    }
    
    private var combinedFCWidth: CGFloat {
        return  AppStyle.FavoritesView.width +
        AppStyle.ChannelView.favButtonTrailing +
        AppStyle.ChannelView.minWidth
    }
    
    var body: some View {
        let compact = isHorizontallyCompact(width: guideWidth)
        
        ZStack {
            if swiftDataController.channelBundleMap.mapCount > 0 {
                
                //Guide content vertical scroll view.
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading) {
                            ForEach(swiftDataController.channelBundleMap.channelIds, id: \.self) { channelId in
                                HStack(alignment: .top,
                                       spacing: AppStyle.GuideView.programSpacing) {
                                    ChannelViewLoader(channelId: channelId)
                                        .id(channelId)
                                        .frame(minWidth: combinedFCWidth)
                                        .frame(width: (compact) ? nil : combinedFCWidth)
                                    
                                    if !compact {
                                        ChannelProgramListView(channelId: channelId)
                                    }
                                }
                            }
                        }
                    }
                    .contentMargins(.top, 5)
                    .contentMargins(.bottom, 5)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { guideWidth = geo.size.width }
                                .onChange(of: geo.size.width) { _, newWidth in
                                    if guideWidth != newWidth {
                                        guideWidth = newWidth
                                    }
                                }
                        }
                    )
#if os(tvOS)
                    .focusSection()
#endif
                    .onAppear {
                        swiftDataController.deletePastChannelPrograms()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            scrollToSelected(proxy: proxy)
                        }
                    }
                    
                    .onChange(of: swiftDataController.channelBundleMap.mapCount) { _, _ in
                        scrollToSelected(proxy: proxy)
                    }
                }
                
            } else {
                if swiftDataController.showFavoritesOnly {
                    NoChannelsFavorites()
                } else {
                    NoChannelsInChannelBundle()
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
            try? await Task.sleep(nanoseconds: codeDebounceNS)
            guard !Task.isCancelled else { return }
            
            if let channelId = appState.selectedChannel {
                proxy.scrollTo(channelId, anchor: .center)
            }
        }
    }
}

//MARK: - PREVIEWS

#Preview("GuideView") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    //Test show only favorites
//    swiftDataController.showFavoritesOnly = false
    
    //Test the no channels view
//    swiftDataController.channelBundleMap.update(map: [])
    
    return TVPreviewView() {
        GuideView()
    }
}
