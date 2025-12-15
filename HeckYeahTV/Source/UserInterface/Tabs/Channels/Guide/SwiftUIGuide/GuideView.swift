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
    
    @State private var rebuildChannelMapTask: Task<Void, Never>? = nil
    @State private var scrollToSelectedTask: Task<Void, Never>? = nil
    
    private let corner: CGFloat = 14
    private let hideGuideInfo: Bool = false
    
    var body: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 15) {
                        ForEach(0..<swiftDataController.guideChannelMap.totalCount, id: \.self) { index in
                            let channelId = swiftDataController.guideChannelMap.map[index]
                            GuideRowLazy(channelId: channelId,
                                         appState: $appState,
                                         hideGuideInfo: hideGuideInfo)
                            .id(channelId)
                            .frame(height: 90) // Fixed height to prevent jumping
                            .padding(.leading, 10)
                            .padding(.trailing, 10)
                        }
                    }
                }
                .background(.clear)
                .contentMargins(.top, 10)
                .contentMargins(.bottom, 5)
                .scrollIndicators(.visible)
#if os(tvOS)
                .focusSection()
#endif
                .onAppear {
                    scrollToSelected(proxy: proxy)
                }
                
                .onChange(of: swiftDataController.guideChannelMap.totalCount) { _, _ in
                    scrollToSelected(proxy: proxy)
                }
            }
            
            if swiftDataController.guideChannelMap.totalCount == 0 {
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
    
    private func scrollToSelected(proxy: ScrollViewProxy) {
        // Avoid multiple consecutive calls by cancelling the previous task.
        scrollToSelectedTask?.cancel()
        scrollToSelectedTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: debounceNS)
                try Task.checkCancellation()
                
                if let channelId = appState.selectedChannel {
                    if let index = swiftDataController.guideChannelMap.map.firstIndex(of: channelId) {
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

#if !os(tvOS)
#Preview("GuideView") {
    @Previewable @State var appState: AppStateProvider = SharedAppState.shared
    let mockData = MockDataPersistence(appState: appState)

    let swiftController = MockSwiftDataController(viewContext: mockData.context,
                                                  selectedCountry: "US",
                                                  selectedCategory: nil,//"news",
                                                  showFavoritesOnly: false,
                                                  searchTerm: nil)//"Lo")
    InjectedValues[\.swiftDataController] = swiftController

    return GuideView(appState: $appState)
        .environment(\.modelContext, mockData.context)
 
}
#endif
